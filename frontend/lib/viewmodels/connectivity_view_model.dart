import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityViewModel extends ChangeNotifier {
  static ConnectivityViewModel? _instance;
  
  /// Global access to trigger offline mode from any HTTP service layer immediately
  static void setGlobalOffline() {
    _instance?.setOffline();
  }

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  Timer? _timer;

  ConnectivityViewModel() {
    _instance = this;
    // Initial check on startup
    checkConnection();
    // Periodically monitor the connection every 7 seconds to catch middle-way drops
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _silentCheck();
    });
  }

  @override
  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
    _timer?.cancel();
    super.dispose();
  }

  /// Public check connection typically used by the "Retry" button with a loading state
  Future<bool> checkConnection() async {
    if (_isChecking) return !_isOffline;
    _isChecking = true;
    notifyListeners();

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (_isOffline) {
          _isOffline = false;
          notifyListeners();
        }
      } else {
        if (!_isOffline) {
          _isOffline = true;
          notifyListeners();
        }
      }
    } catch (_) {
      if (!_isOffline) {
        _isOffline = true;
        notifyListeners();
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
    return !_isOffline;
  }

  /// Internal silent check to avoid showing loading indicator while user is browsing
  Future<void> _silentCheck() async {
    if (_isChecking) return; // Prevent overwriting active retry check state
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      bool currentStatus = result.isEmpty || result[0].rawAddress.isEmpty;
      if (_isOffline != currentStatus) {
        _isOffline = currentStatus;
        notifyListeners();
      }
    } catch (_) {
      if (!_isOffline) {
        _isOffline = true;
        notifyListeners();
      }
    }
  }

  /// Force offline state immediately when an API call fails with a network exception
  void setOffline() {
    if (!_isOffline) {
      _isOffline = true;
      notifyListeners();
    }
  }
}
