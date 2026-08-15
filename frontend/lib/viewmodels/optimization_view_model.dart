import 'package:flutter/material.dart';
import '../services/optimization_service.dart';
import '../models/grocery_product.dart';

class OptimizationViewModel extends ChangeNotifier {
  final OptimizationService _optimizationService;

  Map<String, dynamic>? _singleStoreOptimization;
  Map<String, dynamic>? get singleStoreOptimization => _singleStoreOptimization;

  Map<String, dynamic>? _multiStoreOptimization;
  Map<String, dynamic>? get multiStoreOptimization => _multiStoreOptimization;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  OptimizationViewModel(this._optimizationService);

  Future<void> fetchSingleStoreOptimization({
    required String token,
    required double latitude,
    required double longitude,
    required List<int> itemCodes,
  }) async {
    if (itemCodes.isEmpty) return;
    
    _isLoading = true;
    _singleStoreOptimization = null;
    notifyListeners();

    try {
      _singleStoreOptimization = await _optimizationService.fetchSingleStoreOptimization(
        token: token,
        latitude: latitude,
        longitude: longitude,
        itemCodes: itemCodes,
      );
    } catch (e) {
      debugPrint('Error fetching optimization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMultiStoreOptimization({
    required String token,
    required double latitude,
    required double longitude,
    required List<int> itemCodes,
  }) async {
    if (itemCodes.isEmpty) return;

    _isLoading = true;
    _multiStoreOptimization = null;
    notifyListeners();

    try {
      _multiStoreOptimization = await _optimizationService.fetchMultiStoreOptimization(
        token: token,
        latitude: latitude,
        longitude: longitude,
        itemCodes: itemCodes,
      );
    } catch (e) {
      debugPrint('Error fetching multi-store optimization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearOptimization() {
    _singleStoreOptimization = null;
    _multiStoreOptimization = null;
    notifyListeners();
  }
}
