import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/grocery_product.dart';
import '../models/item_group.dart';
import '../services/grocery_service.dart';

class GroceryViewModel extends ChangeNotifier {
  final GroceryService _groceryService;

  List<GroceryProduct> _allProducts = [];
  List<GroceryProduct> get allProducts => _allProducts;

  List<GroceryProduct> get visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _allProducts.where((product) {
      return query.isEmpty || product.name.toLowerCase().contains(query);
    }).toList();
  }

  List<ItemGroup> _itemGroups = [];
  List<ItemGroup> get itemGroups => _itemGroups;

  final TextEditingController _searchController = TextEditingController();
  TextEditingController get searchController => _searchController;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  // Categorized Products State
  List<GroceryProduct> _categorizedProducts = [];
  List<GroceryProduct> get categorizedProducts => _categorizedProducts;

  bool _isCategorizedLoading = false;
  bool get isCategorizedLoading => _isCategorizedLoading;

  bool _hasMoreProducts = true;
  bool get hasMoreProducts => _hasMoreProducts;

  int _currentOffset = 0;
  final int _pageSize = 20;

  // All Products Pagination State
  bool _hasMoreAllProducts = true;
  bool get hasMoreAllProducts => _hasMoreAllProducts;
  int _allProductsOffset = 0;

  // Product Details State
  Map<String, dynamic>? _selectedProductDetails;
  Map<String, dynamic>? get selectedProductDetails => _selectedProductDetails;

  bool _isDetailsLoading = false;
  bool get isDetailsLoading => _isDetailsLoading;

  String? _detailsError;
  String? get detailsError => _detailsError;

  // Worth Buying State
  List<Map<String, dynamic>> _worthBuyingProducts = [];
  List<Map<String, dynamic>> get worthBuyingProducts => _worthBuyingProducts;
  bool _isWorthBuyingLoading = false;
  bool get isWorthBuyingLoading => _isWorthBuyingLoading;
  bool _hasFetchedWorthBuying = false;
  bool get hasFetchedWorthBuying => _hasFetchedWorthBuying;

  // Most Viewed Products State
  List<GroceryProduct> _mostViewedProducts = [];
  List<GroceryProduct> get mostViewedProducts => _mostViewedProducts;

  String? _currentUserId;
  bool _isMostViewedLoading = false;

  GroceryViewModel(this._groceryService) {
    _searchController.addListener(_onSearchChanged);
    // Initial data load
    loadProducts();
    loadCategories();
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  void updateUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      // We use a microtask to ensure we don't call notifyListeners during a build phase
      Future.microtask(() => loadMostViewedProducts());
    }
  }

  Future<void> loadProducts({bool isRefresh = true}) async {
    if (isRefresh) {
      _allProductsOffset = 0;
      _allProducts = [];
      _hasMoreAllProducts = true;
    } else {
      if (!_hasMoreAllProducts || _isLoading) return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newProducts = await _groceryService.fetchProducts(
        limit: _pageSize,
        offset: _allProductsOffset,
      );

      if (newProducts.length < _pageSize) {
        _hasMoreAllProducts = false;
      }

      _allProducts.addAll(newProducts);
      _allProductsOffset += newProducts.length;
    } catch (e) {
      debugPrint('Error fetching all products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();
    try {
      _itemGroups = await _groceryService.fetchCategories();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategorizedProducts({
    String? group,
    String? category,
    bool? isHalal,
    bool isRefresh = true,
  }) async {
    if (isRefresh) {
      _currentOffset = 0;
      _categorizedProducts = [];
      _hasMoreProducts = true;
    } else {
      if (!_hasMoreProducts || _isCategorizedLoading) return;
    }

    _isCategorizedLoading = true;
    notifyListeners();

    try {
      final newProducts = await _groceryService.fetchProducts(
        itemGroup: group,
        itemCategory: category,
        isHalal: isHalal,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (newProducts.length < _pageSize) {
        _hasMoreProducts = false;
      }

      _categorizedProducts.addAll(newProducts);
      _currentOffset += newProducts.length;
    } catch (e) {
      debugPrint('Error fetching categorized products: $e');
    } finally {
      _isCategorizedLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductDetails({required int itemCode, required double lat, required double lng}) async {
    _isDetailsLoading = true;
    _selectedProductDetails = null;
    _detailsError = null;
    notifyListeners();

    try {
      _selectedProductDetails = await _groceryService.fetchProductDetails(itemCode: itemCode, lat: lat, lng: lng);
      if (_selectedProductDetails != null && _selectedProductDetails!['item'] != null) {
        incrementViewCount(_selectedProductDetails!['item']);
      }
    } catch (e) {
      debugPrint("Error loading product details: $e");
      _detailsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorthBuying({required double lat, required double lng, bool isRefresh = false}) async {
    if (!isRefresh && _isWorthBuyingLoading) return;
    
    _isWorthBuyingLoading = true;
    if (isRefresh) {
      _hasFetchedWorthBuying = false;
    }
    notifyListeners();
    
    try {
      final response = await _groceryService.fetchWorthBuying(latitude: lat, longitude: lng);
      _worthBuyingProducts = List<Map<String, dynamic>>.from(response['results'] ?? []);
      _hasFetchedWorthBuying = true;
    } catch (e) {
      debugPrint('Error loading worth buying products: $e');
      _worthBuyingProducts = [];
      _hasFetchedWorthBuying = true;
    } finally {
      _isWorthBuyingLoading = false;
      notifyListeners();
    }
  }

  Future<void> incrementViewCount(GroceryProduct product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String prefix = _currentUserId ?? 'guest';

      final String? countsJson = prefs.getString('${prefix}_product_view_counts');
      Map<String, dynamic> counts = countsJson != null ? json.decode(countsJson) : {};

      final String itemCodeStr = product.itemCode.toString();
      int currentCount = counts[itemCodeStr] ?? 0;
      counts[itemCodeStr] = currentCount + 1;

      await prefs.setString('${prefix}_product_view_counts', json.encode(counts));

      final String? productsJson = prefs.getString('${prefix}_viewed_products_data');
      Map<String, dynamic> productsData = productsJson != null ? json.decode(productsJson) : {};
      productsData[itemCodeStr] = product.toJson();
      await prefs.setString('${prefix}_viewed_products_data', json.encode(productsData));

      loadMostViewedProducts();
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> loadMostViewedProducts() async {
    if (_isMostViewedLoading) return;
    _isMostViewedLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String prefix = _currentUserId ?? 'guest';

      final String? countsJson = prefs.getString('${prefix}_product_view_counts');
      if (countsJson == null) {
        _mostViewedProducts = [];
        return;
      }

      Map<String, dynamic> counts = json.decode(countsJson);
      final String? productsJson = prefs.getString('${prefix}_viewed_products_data');
      if (productsJson == null) {
        _mostViewedProducts = [];
        return;
      }
      Map<String, dynamic> productsData = json.decode(productsJson);

      List<MapEntry<String, dynamic>> filteredEntries = counts.entries
          .where((entry) => (entry.value as int) >= 5)
          .toList();

      filteredEntries.sort((a, b) => (b.value as int).compareTo(a.value as int));
      final top5Entries = filteredEntries.take(5).toList();

      _mostViewedProducts = top5Entries.map((entry) {
        return GroceryProduct.fromJson(productsData[entry.key]);
      }).toList();
    } catch (e) {
      debugPrint('Error loading most viewed products: $e');
      _mostViewedProducts = [];
    } finally {
      _isMostViewedLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
