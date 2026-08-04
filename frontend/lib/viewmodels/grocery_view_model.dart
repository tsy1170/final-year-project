import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/grocery_product.dart';
import '../models/item_group.dart';
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

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  GroceryViewModel() {
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
      // Ensure we have a position, otherwise try to fetch it again
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
      // Fallback to default Penang coordinates if location fails
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
