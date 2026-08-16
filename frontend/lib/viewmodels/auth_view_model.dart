import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final _storage = const FlutterSecureStorage();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  String? _userName;
  String? get userName => _userName;

  String? _userEmail;
  String? get userEmail => _userEmail;

  String? _accessToken;
  String? get accessToken => _accessToken;

  bool _isRegistering = false;
  bool get isRegistering => _isRegistering;

  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  AuthViewModel(this._authService) {
    _checkLoginStatus();
  }

  // This is the global callback for all services to trigger a logout
  void handleServiceResponse(int statusCode) {
    if (statusCode == 401) {
      logout();
    }
  }

  Future<void> _checkLoginStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final userData = await _authService.getCurrentUser(token);
        _userName = userData['user_name'];
        _userEmail = userData['email'];
        _accessToken = token;
        _isLoggedIn = true;
      } catch (e) {
        debugPrint('Auto-login check failed: $e');
        await logout();
      }
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isRegistering = true;
    notifyListeners();
    try {
      final success = await _authService.register(
        userName: name,
        email: email,
        password: password,
      );
      return success;
    } catch (e) {
      rethrow;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoggingIn = true;
    notifyListeners();
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      final token = response['access_token'];
      final userData = response['user'];

      await _storage.write(key: 'access_token', value: token);
      await _storage.write(key: 'user_name', value: userData['user_name']);
      await _storage.write(key: 'user_email', value: userData['email']);

      _userName = userData['user_name'];
      _userEmail = userData['email'];
      _accessToken = token;
      _isLoggedIn = true;

      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _accessToken = null;
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    if (_accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }
    _isUpdating = true;
    notifyListeners();
    try {
      final response = await _authService.updateUsername(_accessToken!, newUsername);
      final userData = response['user'];
      _userName = userData['user_name'];
      await _storage.write(key: 'user_name', value: _userName);
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateEmail(String newEmail, String currentPassword) async {
    if (_accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }
    _isUpdating = true;
    notifyListeners();
    try {
      await _authService.updateEmail(_accessToken!, newEmail, currentPassword);
      await logout();
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword, String currentPassword) async {
    if (_accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }
    _isUpdating = true;
    notifyListeners();
    try {
      await _authService.updatePassword(_accessToken!, newPassword, currentPassword);
      await logout();
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
