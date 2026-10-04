import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

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

  String? _fcmToken;

  bool _isRegistering = false;
  bool get isRegistering => _isRegistering;

  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  bool _isRefreshing = false;

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  bool _isBiometricSupported = false;
  bool get isBiometricSupported => _isBiometricSupported;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthViewModel(this._authService) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.wait([
        _checkLoginStatus(),
        _checkBiometricSupport(),
      ]);
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      _isBiometricSupported = canAuthenticateWithBiometrics && isDeviceSupported;

      final String? enabled = await _storage.read(key: 'is_biometric_enabled');
      _isBiometricEnabled = enabled == 'true';
    } catch (e) {
      _isBiometricSupported = false;
      debugPrint('Error checking biometric support: $e');
    }
  }

  void handleServiceResponse(int statusCode) {
    if (statusCode == 401) {
      refreshAccessToken();
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        _accessToken = token;
        try {
          await _fetchAndSetUserInfo(token);
          _isLoggedIn = true;
          if (_fcmToken != null) {
            await syncFcmToken(_fcmToken);
          }
        } catch (e) {
          debugPrint('Access token expired or fetch failed. Attempting silent refresh...');
          await refreshAccessToken();
        }
      }
    } catch (e) {
      debugPrint('Check login status error: $e');
      if (e.toString().contains('InvalidKeyException') || e.toString().contains('Failed to unwrap key')) {
        debugPrint('Keystore issue detected. Clearing storage.');
        await logout(hardLogout: true);
      }
    }
  }

  Future<void> refreshAccessToken() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _authService.refreshToken(refreshToken);
      final newAccessToken = response['access_token'];

      _accessToken = newAccessToken;
      await _storage.write(key: 'access_token', value: newAccessToken);

      await _fetchAndSetUserInfo(newAccessToken);

      _isLoggedIn = true;
      debugPrint('Token refreshed successfully');
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
      _isLoggedIn = false;
      _accessToken = null;
    } finally {
      _isRefreshing = false;
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

  Future<void> setFcmToken(String? token) async {
    _fcmToken = token;
    if (_isLoggedIn && token != null) {
      await syncFcmToken(token);
    }
  }

  Future<void> syncFcmToken(String? token) async {
    if (_accessToken != null && token != null) {
      try {
        await _authService.updateFcmToken(_accessToken!, token);
        debugPrint("FCM Token updated successfully on backend");
      } catch (e) {
        debugPrint("Failed to update FCM token: $e");
      }
    }
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
      final refreshToken = response['refresh_token'];
      _accessToken = token;
      await _storage.write(key: 'access_token', value: token);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      await _fetchAndSetUserInfo(token);

      _isLoggedIn = true;

      if (_fcmToken != null) {
        await syncFcmToken(_fcmToken);
      }

      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithBiometrics() async {
    if (!_isBiometricEnabled || !_isBiometricSupported) return false;

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isLoggingIn = true;
        notifyListeners();

        await refreshAccessToken();

        if (_isLoggedIn) {
          if (_fcmToken != null) {
            await syncFcmToken(_fcmToken);
          }
          _isLoggingIn = false;
          notifyListeners();
          return true;
        }

        _isLoggingIn = false;
        notifyListeners();
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('Biometric login failed: $e');
      _isLoggingIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> enableBiometrics() async {
    if (!_isBiometricSupported) return;

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm to enable biometric login',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (authenticated) {
        _isBiometricEnabled = true;
        await _storage.write(key: 'is_biometric_enabled', value: 'true');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error enabling biometrics: $e');
    }
  }

  Future<void> disableBiometrics() async {
    _isBiometricEnabled = false;
    await _storage.write(key: 'is_biometric_enabled', value: 'false');
    notifyListeners();
  }

  Future<void> logout({bool hardLogout = false}) async {
    if (hardLogout) {
      await _storage.deleteAll();
      _isBiometricEnabled = false;
    } else {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'user_name');
      await _storage.delete(key: 'user_nric');
      await _storage.delete(key: 'user_email');
      await _storage.delete(key: 'user_phone');
      await _storage.delete(key: 'user_dob');
    }

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
      await logout(hardLogout: true);
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
      await logout(hardLogout: true);
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
