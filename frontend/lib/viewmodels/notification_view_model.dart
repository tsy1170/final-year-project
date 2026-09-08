import 'package:flutter/material.dart';
import '../models/price_alert.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService;

  List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => _alerts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NotificationViewModel(this._notificationService);

  Future<void> fetchPriceAlerts(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _alerts = await _notificationService.fetchPriceAlerts(token);
    } catch (e) {
      debugPrint('Error loading price alerts: $e');
      _alerts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createPriceAlert(String token, int itemCode, double targetPrice, double? latitude, double? longitude) async {
    try {
      final response = await _notificationService.createPriceAlert(token, itemCode, targetPrice, latitude, longitude);
      return response['message'] ?? 'Price alert created';
    } catch (e) {
      debugPrint('Error creating price alert: $e');
      rethrow;
    }
  }

  Future<String> removePriceAlert(String token, int alertId) async {
    try {
      final response = await _notificationService.deletePriceAlert(token, alertId);
      _alerts.removeWhere((alert) => alert.alertId == alertId);
      notifyListeners();
      return response['message'] ?? 'Price alert removed';
    } catch (e) {
      debugPrint('Error deleting price alert: $e');
      rethrow;
    }
  }

  void clearAlerts() {
    _alerts = [];
    notifyListeners();
  }
}
