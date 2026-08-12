import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/grocery_product.dart';
import '../models/item_group.dart';
import '../models/store_price.dart';

class GroceryService {
  static const String baseUrl = 'http://192.168.1.115:8000';
  VoidCallback? onUnauthorized;

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
  }

  Future<List<GroceryProduct>> demoFetchProducts() async {
    return const [
      GroceryProduct(itemCode: 1, name: 'AYAM BERSIH - STANDARD', unit: '1 KG'),
      GroceryProduct(itemCode: 2, name: '100 PLUS (ORIGINAL)', unit: '1.5 L'),
      GroceryProduct(itemCode: 129, name: 'ANGGUR HIJAU BERBIJI', unit: '1 KG'),
      GroceryProduct(itemCode: 1550, name: 'TIMUN', unit: '1 KG'),
      GroceryProduct(itemCode: 5, name: 'AYAM BERSIH - STANDARD', unit: '1 KG'),
      GroceryProduct(itemCode: 6, name: '100 PLUS (ORIGINAL)', unit: '1.5 L'),
      GroceryProduct(itemCode: 7, name: 'ANGGUR HIJAU BERBIJI', unit: '1 KG'),
      GroceryProduct(itemCode: 8, name: 'TIMUN', unit: '1 KG'),
    ];
  }

  Future<List<GroceryProduct>> fetchProducts({
    String? itemGroup,
    String? itemCategory,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (itemGroup != null) queryParams['item_group'] = itemGroup;
      if (itemCategory != null) queryParams['item_category'] = itemCategory;

      final url = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
      final response = await http.get(url);
      _handleResponse(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'];
        return productsJson.map((json) => GroceryProduct.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<ItemGroup>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/categories'));
      _handleResponse(response);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> groupsJson = data['item_groups'];
        return groupsJson.map((json) => ItemGroup.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchProductDetails({
    required int itemCode,
    required double lat,
    required double lng,
    double radius = 10.0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/products/$itemCode/nearby-price-levels').replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'radius_km': radius.toString(),
      });

      final response = await http.get(url);
      _handleResponse(response);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'item': GroceryProduct.fromJson(data['item']),
          'price_summary': data['price_summary'],
          'stores': (data['stores'] as List)
              .map((store) => StorePrice.fromJson(store))
              .toList(),
        };
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      print('Error fetching product details: $e');
      rethrow;
    }
  }

  Future<List<GroceryProduct>> searchProducts(String query) async {
    try {
      final url = Uri.parse('$baseUrl/products/search').replace(queryParameters: {'q': query});
      final response = await http.get(url);
      _handleResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => GroceryProduct.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  Future<bool> register({
    required String userName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'email': email,
        'password': password,
      }),
    );
    _handleResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      String errorMessage = 'Registration failed';
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (errorData['detail'] != null) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        // Fallback
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    
    // OAuth2PasswordRequestForm expects application/x-www-form-urlencoded
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email, // backend expects 'username' for OAuth2 form
        'password': password,
      },
    );
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      String errorMessage = 'Login failed';
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (errorData['detail'] != null) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        // Fallback
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch current user');
    }
  }

  Future<List<GroceryProduct>> fetchFavourites(String token) async {
    final url = Uri.parse('$baseUrl/favourites');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(response);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> favouritesJson = data['favourites'];
      return favouritesJson.map((json) => GroceryProduct.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch favourites');
    }
  }

  Future<void> addFavourite(String token, int itemCode) async {
    final url = Uri.parse('$baseUrl/favourites');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'item_code': itemCode}),
    );
    _handleResponse(response);
  }

  Future<void> removeFavourite(String token, int itemCode) async {
    final url = Uri.parse('$baseUrl/favourites/$itemCode');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> fetchSingleStoreOptimization({
    required String token,
    required double latitude,
    required double longitude,
    required List<int> itemCodes,
    double radiusKm = 10.0,
    double travelCostPerKm = 0.15,
  }) async {
    final url = Uri.parse('$baseUrl/basket-optimizations/single-store');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'basket_items': itemCodes.map((code) => {'item_code': code}).toList(),
        'radius_km': radiusKm,
        'travel_cost_per_km': travelCostPerKm,
      }),
    );
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch single store optimization');
    }
  }

  Future<Map<String, dynamic>> fetchMultiStoreOptimization({
    required String token,
    required double latitude,
    required double longitude,
    required List<int> itemCodes,
    double radiusKm = 10.0,
    double travelCostPerKm = 0.15,
  }) async {
    final url = Uri.parse('$baseUrl/basket-optimizations/multi-store');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'basket_items': itemCodes.map((code) => {'item_code': code}).toList(),
        'radius_km': radiusKm,
        'travel_cost_per_km': travelCostPerKm,
      }),
    );
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch multi store optimization');
    }
  }
}
