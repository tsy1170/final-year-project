import 'package:flutter/material.dart';
import '../models/grocery_product.dart';
import '../services/favourite_service.dart';

class FavouriteViewModel extends ChangeNotifier {
  final FavouriteService _favouriteService;
  String? _lastToken;

  final Set<int> _favourites = <int>{};
  Set<int> get favourites => _favourites;

  List<GroceryProduct> _favouriteProducts = [];
  List<GroceryProduct> get favouriteProducts => _favouriteProducts;

  List<Map<String, dynamic>> _worthBuyingFavourites = [];
  List<Map<String, dynamic>> get worthBuyingFavourites => _worthBuyingFavourites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isWorthBuyingLoading = false;
  bool get isWorthBuyingLoading => _isWorthBuyingLoading;

  FavouriteViewModel(this._favouriteService);

  Future<void> loadFavourites(String token) async {
    if (_lastToken == token && _favouriteProducts.isNotEmpty) return;
    _lastToken = token;
    _isLoading = true;
    notifyListeners();
    
    try {
      final favs = await _favouriteService.fetchFavourites(token);
      _favouriteProducts = favs;
      _favourites.clear();
      _favourites.addAll(favs.map((e) => e.itemCode));
    } catch (e) {
      debugPrint('Error loading favourites: $e');
      _lastToken = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorthBuyingFavourites(String token, double lat, double lng) async {
    _isWorthBuyingLoading = true;
    notifyListeners();

    try {
      final response = await _favouriteService.fetchFavouritesWorthBuying(
        token: token,
        latitude: lat,
        longitude: lng,
      );
      _worthBuyingFavourites = List<Map<String, dynamic>>.from(response['results'] ?? []);
    } catch (e) {
      debugPrint('Error loading worth buying favourites: $e');
      _worthBuyingFavourites = [];
    } finally {
      _isWorthBuyingLoading = false;
      notifyListeners();
    }
  }

  void clearFavourites() {
    _favourites.clear();
    _favouriteProducts = [];
    _worthBuyingFavourites = [];
    _lastToken = null;
    notifyListeners();
  }

  Future<void> toggleFavourite(int itemCode, String token, {double? lat, double? lng}) async {
    if (_favourites.contains(itemCode)) {
      _favourites.remove(itemCode);
      _favouriteProducts.removeWhere((p) => p.itemCode == itemCode);
      _worthBuyingFavourites.removeWhere((p) => p['item_code'] == itemCode);
      notifyListeners();
      try {
        await _favouriteService.removeFavourite(token, itemCode);
      } catch (e) {
        debugPrint('Error removing favourite: $e');
      }
    } else {
      _favourites.add(itemCode);
      notifyListeners();
      try {
        await _favouriteService.addFavourite(token, itemCode);
        final favs = await _favouriteService.fetchFavourites(token);
        _favouriteProducts = favs;
        _favourites.clear();
        _favourites.addAll(favs.map((e) => e.itemCode));
        
        // Refresh worth buying if location is provided
        if (lat != null && lng != null) {
          await loadWorthBuyingFavourites(token, lat, lng);
        }
        
        notifyListeners();
      } catch (e) {
        _favourites.remove(itemCode);
        notifyListeners();
        debugPrint('Error adding favourite: $e');
      }
    }
  }

  Map<String, dynamic>? getWorthBuyingInfo(int itemCode) {
    try {
      return _worthBuyingFavourites.firstWhere((p) => p['item_code'] == itemCode);
    } catch (_) {
      return null;
    }
  }
}
