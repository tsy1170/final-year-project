import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/grocery_product.dart';
import '../models/item_group.dart';
import '../models/store_price.dart';
import '../services/grocery_service.dart';

class GroceryViewModel extends ChangeNotifier {
  final GroceryService _groceryService = GroceryService();
  final _storage = const FlutterSecureStorage();

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

  // Authentication State
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  String? _userName;
  String? get userName => _userName;

  String? _userEmail;
  String? get userEmail => _userEmail;

  bool _isRegistering = false;
  bool get isRegistering => _isRegistering;

  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;

  GroceryViewModel() {
    _groceryService.onUnauthorized = () => logout();
    _searchController.addListener(_onSearchChanged);
    loadProducts();
    loadCategories();
    _initLocation();
    _checkLoginStatus();
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final userData = await _groceryService.getCurrentUser(token);
        _userName = userData['user_name'];
        _userEmail = userData['email'];
        _isLoggedIn = true;
      } catch (e) {
        debugPrint('Auto-login check failed: $e');
        await logout();
      }
      notifyListeners();
    }
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
    // Using demoFetchProducts for offline demo in main view
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

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
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

      _selectedProductDetails = await _groceryService.fetchProductDetails(
        itemCode: itemCode,
        lat: lat,
        lng: lng
      );
    } catch (e) {
      print("Error loading product details: $e");
      _selectedProductDetails = await _groceryService.fetchProductDetails(
        itemCode: itemCode,
        lat: 5.356,
        lng: 100.301
      );
    } finally {
      _isDetailsLoading = false;
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
      final success = await _groceryService.register(
        userName: name,
        email: email,
        password: password,
      );
      
      return success;
    } catch (e) {
      // Rethrow to let the view handle the error message
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
      final response = await _groceryService.login(
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
