import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class AuthService {
  final String baseUrl = ApiConstants.baseUrl;
  void Function(int)? onResponseStatus;
  final Duration timeoutDuration = const Duration(seconds: 15);

  AuthService({this.onResponseStatus});

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onResponseStatus?.call(401);
    }
  }

  Future<bool> register({
    required String userName,
    required String nric,
    required String email,
    required String password,
    required String phoneNumber,
    required String dob,
  }) async {
    final url = Uri.parse('$baseUrl/users/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'nric': nric,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'dob': dob,
      }),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      String errorMessage = 'Registration failed';
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (errorData['detail'] != null) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        // Fallback
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      String errorMessage = 'Login failed';
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (errorData['detail'] != null) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        // Fallback
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final url = Uri.parse('$baseUrl/users/refresh-token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'refresh_token': refreshToken}),
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to refresh token'));
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch current user');
    }
  }

  Future<Map<String, dynamic>> updateFcmToken(String token, String fcmToken) async {
    final url = Uri.parse('$baseUrl/users/me/fcm-token');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'fcm_token': fcmToken}),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to update FCM token'));
    }
  }

  Future<Map<String, dynamic>> updateUsername(String token, String newUsername) async {
    final url = Uri.parse('$baseUrl/users/me/username');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'user_name': newUsername}),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to update username'));
    }
  }

  Future<Map<String, dynamic>> updateNric(String token, String newNric) async {
    final url = Uri.parse('$baseUrl/users/me/nric');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'nric': newNric}),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to update NRIC'));
    }
  }

  Future<Map<String, dynamic>> updatePhoneNumber(String token, String newPhoneNumber) async {
    final url = Uri.parse('$baseUrl/users/me/phone-number');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'phone_number': newPhoneNumber}),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to update phone number'));
    }
  }

  Future<Map<String, dynamic>> updateDob(String token, String newDob) async {
    final url = Uri.parse('$baseUrl/users/me/dob');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'dob': newDob}),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to update date of birth'));
    }
  }

  Future<Map<String, dynamic>> updateEmail(String token, String newEmail, String currentPassword) async {
    final url = Uri.parse('$baseUrl/users/me/email');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'new_email': newEmail,
        'current_password': currentPassword,
      }),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to update email'));
    }
  }

  Future<Map<String, dynamic>> updatePassword(String token, String newPassword, String currentPassword) async {
    final url = Uri.parse('$baseUrl/users/me/password');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    ).timeout(timeoutDuration);
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response.body, 'Failed to update password'));
    }
  }

  String _parseError(String responseBody, String defaultMessage) {
    try {
      final Map<String, dynamic> errorData = json.decode(responseBody);
      return errorData['detail']?.toString() ?? defaultMessage;
    } catch (e) {
      return defaultMessage;
    }
  }
}
