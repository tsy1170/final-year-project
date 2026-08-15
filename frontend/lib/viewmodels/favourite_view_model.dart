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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FavouriteViewModel(this._favouriteService);

  Future<void> loadFavourites(String token) async {
    if (_lastToken == token) return;
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

  void clearFavourites() {
    _favourites.clear();
    _favouriteProducts = [];
    _lastToken = null;
    notifyListeners();
  }

  Future<void> toggleFavourite(int itemCode, String token) async {
    if (_favourites.contains(itemCode)) {
      _favourites.remove(itemCode);
      _favouriteProducts.removeWhere((p) => p.itemCode == itemCode);
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
        notifyListeners();
      } catch (e) {
        _favourites.remove(itemCode);
        notifyListeners();
        debugPrint('Error adding favourite: $e');
      }
    }
  }
}
