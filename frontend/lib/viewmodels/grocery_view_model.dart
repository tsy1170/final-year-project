import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/grocery_product.dart';
import '../models/item_group.dart';
import '../models/store_price.dart';
import '../services/grocery_service.dart';

class GroceryViewModel extends ChangeNotifier {
  final GroceryService _groceryService;
  String? _lastToken;

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

  final Set<int> _favourites = <int>{};
  Set<int> get favourites => _favourites;

  List<GroceryProduct> _favouriteProducts = [];
  List<GroceryProduct> get favouriteProducts => _favouriteProducts;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  bool _isFavouritesLoading = false;
  bool get isFavouritesLoading => _isFavouritesLoading;

  // Categorized Products State
  List<GroceryProduct> _categorizedProducts = [];
  List<GroceryProduct> get categorizedProducts => _categorizedProducts;

  bool _isCategorizedLoading = false;
  bool get isCategorizedLoading => _isCategorizedLoading;

  bool _hasMoreProducts = true;
  bool get hasMoreProducts => _hasMoreProducts;

  int _currentOffset = 0;
  final int _pageSize = 20;

  // Product Details State
  Map<String, dynamic>? _selectedProductDetails;
  Map<String, dynamic>? get selectedProductDetails => _selectedProductDetails;
  
  bool _isDetailsLoading = false;
  bool get isDetailsLoading => _isDetailsLoading;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  GroceryViewModel(this._groceryService) {
    _searchController.addListener(_onSearchChanged);
    loadProducts();
    loadCategories();
    _initLocation();
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  Future<void> _initLocation() async {
    try {
      _currentPosition = await _determinePosition();
      notifyListeners();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _allProducts = await _groceryService.demoFetchProducts();
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

  Future<void> loadFavourites(String token) async {
    if (_lastToken == token) return; // Prevent redundant loads
    _lastToken = token;
    _isFavouritesLoading = true;
    notifyListeners();
    
    try {
      final favs = await _groceryService.fetchFavourites(token);
      _favouriteProducts = favs;
      _favourites.clear();
      _favourites.addAll(favs.map((e) => e.itemCode));
    } catch (e) {
      debugPrint('Error loading favourites: $e');
      _lastToken = null;
    } finally {
      _isFavouritesLoading = false;
      notifyListeners();
    }
  }

  void clearFavourites() {
    _favourites.clear();
    _favouriteProducts = [];
    _lastToken = null;
    notifyListeners();
  }

  Future<void> fetchCategorizedProducts({
    String? group,
    String? category,
    bool isRefresh = true,
  }) async {
    if (isRefresh) {
      _currentOffset = 0;
      _categorizedProducts = [];
      _hasMoreProducts = true;
      _isCategorizedLoading = true;
    } else {
      if (!_hasMoreProducts || _isCategorizedLoading) return;
    }

    notifyListeners();

    try {
      final newProducts = await _groceryService.fetchProducts(
        itemGroup: group,
        itemCategory: category,
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

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> loadProductDetails(int itemCode) async {
    _isDetailsLoading = true;
    _selectedProductDetails = null;
    notifyListeners();
    
    try {
      _currentPosition ??= await _determinePosition();
      double lat = _currentPosition?.latitude ?? 5.356;
      double lng = _currentPosition?.longitude ?? 100.301;
      _selectedProductDetails = await _groceryService.fetchProductDetails(itemCode: itemCode, lat: lat, lng: lng);
    } catch (e) {
      debugPrint("Error loading product details: $e");
      _selectedProductDetails = await _groceryService.fetchProductDetails(itemCode: itemCode, lat: 5.356, lng: 100.301);
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavourite(int itemCode, String token) async {
    if (_favourites.contains(itemCode)) {
      _favourites.remove(itemCode);
      _favouriteProducts.removeWhere((p) => p.itemCode == itemCode);
      notifyListeners();
      try {
        await _groceryService.removeFavourite(token, itemCode);
      } catch (e) {
        debugPrint('Error removing favourite: $e');
      }
    } else {
      _favourites.add(itemCode);
      notifyListeners();
      try {
        await _groceryService.addFavourite(token, itemCode);
        // Refresh to get full product info for the Favourites page
        final favs = await _groceryService.fetchFavourites(token);
        _favouriteProducts = favs;
        _favourites.clear();
        _favourites.addAll(favs.map((e) => e.itemCode));
        notifyListeners();
      } catch (e) {
        _favourites.remove(itemCode);
        notifyListeners();
        debugPrint('Error adding favourite: $e');
      }
    }
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
