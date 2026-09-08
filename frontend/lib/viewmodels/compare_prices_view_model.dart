import 'package:flutter/material.dart';
import '../models/grocery_product.dart';
import '../models/store_price.dart';
import '../services/complaint_service.dart';
import '../services/grocery_service.dart';

class ComparePricesViewModel extends ChangeNotifier {
  final ComplaintService _complaintService;
  final GroceryService _groceryService;

  ComparePricesViewModel(this._complaintService, this._groceryService);

  GroceryProduct? _selectedProduct;
  GroceryProduct? get selectedProduct => _selectedProduct;

  final List<Map<String, dynamic>> _selectedPremises = [];
  List<Map<String, dynamic>> get selectedPremises => _selectedPremises;

  List<Map<String, dynamic>> _nearbyPremises = [];
  List<Map<String, dynamic>> get nearbyPremises => _nearbyPremises;

  List<StorePrice> _comparisonResults = [];
  List<StorePrice> get comparisonResults => _comparisonResults;

  bool _isLoadingPremises = false;
  bool get isLoadingPremises => _isLoadingPremises;

  bool _isFetchingPrices = false;
  bool get isFetchingPrices => _isFetchingPrices;

  void setSelectedProduct(GroceryProduct? product, double? lat, double? lng) {
    _selectedProduct = product;
    fetchPrices(lat, lng);
  }

  Future<void> loadNearbyPremises(double lat, double lng) async {
    _isLoadingPremises = true;
    notifyListeners();
    try {
      _nearbyPremises = await _complaintService.getNearbyPremises(lat, lng);
    } catch (e) {
      debugPrint('Error loading premises: $e');
    } finally {
      _isLoadingPremises = false;
      notifyListeners();
    }
  }

  Future<void> fetchPrices(double? lat, double? lng) async {
    if (_selectedProduct == null || _selectedPremises.isEmpty || lat == null || lng == null) {
      _comparisonResults = [];
      notifyListeners();
      return;
    }

    _isFetchingPrices = true;
    _comparisonResults = [];
    notifyListeners();

    try {
      final details = await _groceryService.fetchProductDetails(
        itemCode: _selectedProduct!.itemCode,
        lat: lat,
        lng: lng,
        radius: 20.0,
      );

      final List<StorePrice> allStores = details['stores'];
      final selectedCodes = _selectedPremises.map((p) => p['premise_code'] as int).toSet();

      _comparisonResults = allStores.where((s) => selectedCodes.contains(s.premiseCode)).toList();
    } catch (e) {
      debugPrint('Error fetching prices: $e');
    } finally {
      _isFetchingPrices = false;
      notifyListeners();
    }
  }

  void addPremise(Map<String, dynamic> premise, double? lat, double? lng) {
    if (_selectedPremises.length >= 4) return;
    _selectedPremises.add(premise);
    fetchPrices(lat, lng);
  }

  void removePremise(int premiseCode, double? lat, double? lng) {
    _selectedPremises.removeWhere((p) => p['premise_code'] == premiseCode);
    fetchPrices(lat, lng);
  }
}
