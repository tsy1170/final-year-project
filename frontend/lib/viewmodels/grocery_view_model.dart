import 'package:flutter/material.dart';
import '../models/grocery_product.dart';
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

  GroceryViewModel() {
    _searchController.addListener(_onSearchChanged);
    loadProducts();
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
