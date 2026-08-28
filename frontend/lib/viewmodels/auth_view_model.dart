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

  String? _userNric;
  String? get userNric => _userNric;

  String? _userEmail;
  String? get userEmail => _userEmail;

  String? _userPhoneNumber;
  String? get userPhoneNumber => _userPhoneNumber;

  String? _userDob;
  String? get userDob => _userDob;

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

  void handleServiceResponse(int statusCode) {
    if (statusCode == 401) {
      logout();
    }
  }

  Future<void> _checkLoginStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      _accessToken = token;
      try {
        await _fetchAndSetUserInfo(token);
        _isLoggedIn = true;
      } catch (e) {
        debugPrint('Auto-login check failed: $e');
        await logout();
      }
      notifyListeners();
    }
  }

  Future<void> _fetchAndSetUserInfo(String token) async {
    final userData = await _authService.getCurrentUser(token);
    _userName = userData['user_name'];
    _userNric = userData['nric'];
    _userEmail = userData['email'];
    _userPhoneNumber = userData['phone_number'];
    _userDob = userData['dob'];

    await _storage.write(key: 'user_name', value: _userName ?? '');
    await _storage.write(key: 'user_nric', value: _userNric ?? '');
    await _storage.write(key: 'user_email', value: _userEmail ?? '');
    await _storage.write(key: 'user_phone', value: _userPhoneNumber ?? '');
    await _storage.write(key: 'user_dob', value: _userDob ?? '');
  }

  Future<bool> register({
    required String name,
    required String nric,
    required String email,
    required String password,
    required String phoneNumber,
    required String dob,
  }) async {
    _isRegistering = true;
    notifyListeners();
    try {
      final success = await _authService.register(
        userName: name,
        nric: nric,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        dob: dob,
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
      _accessToken = token;
      await _storage.write(key: 'access_token', value: token);

      // Fetch full user info right after login
      await _fetchAndSetUserInfo(token);

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
    _userNric = null;
    _userEmail = null;
    _userPhoneNumber = null;
    _userDob = null;
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
      _userName = userData != null ? userData['user_name'] : newUsername;
      await _storage.write(key: 'user_name', value: _userName ?? '');
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateNric(String newNric) async {
    if (_accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }
    _isUpdating = true;
    notifyListeners();
    try {
      final response = await _authService.updateNric(_accessToken!, newNric);
      final userData = response['user'];
      _userNric = userData != null ? userData['nric'] : newNric;
      await _storage.write(key: 'user_nric', value: _userNric ?? '');
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updatePhoneNumber(String newPhoneNumber) async {
    if (_accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }
    _isUpdating = true;
    notifyListeners();
    try {
      final response = await _authService.updatePhoneNumber(_accessToken!, newPhoneNumber);
      final userData = response['user'];
      _userPhoneNumber = userData != null ? userData['phone_number'] : newPhoneNumber;
      await _storage.write(key: 'user_phone', value: _userPhoneNumber ?? '');
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateDob(String newDob) async {
    if (_accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }
    _isUpdating = true;
    notifyListeners();
    try {
      final response = await _authService.updateDob(_accessToken!, newDob);
      final userData = response['user'];
      _userDob = userData != null ? userData['dob'] : newDob;
      await _storage.write(key: 'user_dob', value: _userDob ?? '');
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
