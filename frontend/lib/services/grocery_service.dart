import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grocery_product.dart';
import '../models/item_group.dart';
import '../models/store_price.dart';
import '../constants/api_constants.dart';

class GroceryService {
  final String baseUrl = ApiConstants.baseUrl;
  void Function(int)? onResponseStatus;

  GroceryService({this.onResponseStatus});

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onResponseStatus?.call(401);
    }
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
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to load product details');
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

  Future<Map<String, dynamic>> fetchWorthBuying({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius_km': radiusKm.toString(),
        'limit': limit.toString(),
      };

      final url = Uri.parse('$baseUrl/products/worth-buying').replace(queryParameters: queryParams);
      final response = await http.get(url);
      _handleResponse(response);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load worth buying products');
      }
    } catch (e) {
      print('Error fetching worth buying products: $e');
      return {'results': []};
    }
  }
}
