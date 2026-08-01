import 'package:flutter/material.dart';
import '../models/grocery_product.dart';
import '../models/item_group.dart';
import '../models/store_price.dart';
import '../services/grocery_service.dart';

class GroceryViewModel extends ChangeNotifier {
  final GroceryService _groceryService = GroceryService();

  List<GroceryProduct> _allProducts = [];
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

  String _category = 'All Categories';
  String get category => _category;

  String _subCategory = 'Sub Category';
  String get subCategory => _subCategory;

  final Set<String> _favourites = <String>{};
  Set<String> get favourites => _favourites;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  // Product Details State
  Map<String, dynamic>? _selectedProductDetails;
  Map<String, dynamic>? get selectedProductDetails => _selectedProductDetails;
  
  bool _isDetailsLoading = false;
  bool get isDetailsLoading => _isDetailsLoading;

  GroceryViewModel() {
    _searchController.addListener(_onSearchChanged);
    loadProducts();
    loadCategories();
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _allProducts = await _groceryService.fetchProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();
    _itemGroups = await _groceryService.fetchCategories();
    _isCategoriesLoading = false;
    notifyListeners();
  }

  Future<void> loadProductDetails(int itemCode) async {
    _isDetailsLoading = true;
    _selectedProductDetails = null;
    notifyListeners();
    
    try {
      // Default coordinates for Penang as example
      _selectedProductDetails = await _groceryService.fetchProductDetails(
        itemCode: itemCode, 
        lat: 5.356, 
        lng: 100.301
      );
    } catch (e) {
      print("Error loading product details: $e");
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setSubCategory(String value) {
    _subCategory = value;
    notifyListeners();
  }

  void toggleFavourite(String productName) {
    if (!_favourites.add(productName)) {
      _favourites.remove(productName);
    }
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
