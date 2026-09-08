import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../models/price_alert.dart';
import '../constants/api_constants.dart';

// Top-level background handlers — must be outside class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM message: ${message.messageId}');
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Background notification tapped: ${response.payload}');
}

class NotificationService {
  final String baseUrl = ApiConstants.baseUrl;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  void Function(int)? onResponseStatus;
  void Function(String)? onTokenRefresh;

  NotificationService({this.onResponseStatus, this.onTokenRefresh});

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for price alert notifications.',
    importance: Importance.max,
  );

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onResponseStatus?.call(401);
    }
  }

  Future<void> initNotifications() async {
    // 1. Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('Notification permission denied');
    }

    // 2. Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settingsInit = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(
      settings: settingsInit,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
        // Add navigation logic here
        // e.g. navigate to price alerts page
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 3. Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation
    <AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 4. Set foreground notification presentation options for iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        id: notification.hashCode.abs(), // ← non-negative
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    });

    // 6. Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      onTokenRefresh?.call(newToken);
    });
  }

  Future<String?> getDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<List<PriceAlert>> fetchPriceAlerts(String token) async {
    try {
      final url = Uri.parse('$baseUrl/price-alerts');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      _handleResponse(response);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final alertsJson = data['alerts'] as List<dynamic>;
        return alertsJson
            .map((j) => PriceAlert.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load price alerts');
      }
    } catch (e) {
      debugPrint('Error fetching price alerts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createPriceAlert(
      String token,
      int itemCode,
      double targetPrice,
      double? latitude,
      double? longitude,
      ) async {
    final url = Uri.parse('$baseUrl/price-alerts');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'item_code': itemCode,
        'target_price': targetPrice,
        'user_latitude': latitude,
        'user_longitude': longitude,
      }),
    );
    _handleResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Failed to create price alert');
    }
  }

  Future<Map<String, dynamic>> deletePriceAlert(
      String token,
      int alertId,
      ) async {
    final url = Uri.parse('$baseUrl/price-alerts/$alertId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Failed to delete price alert');
    }
  }
}