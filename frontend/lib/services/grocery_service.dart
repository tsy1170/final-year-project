import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grocery_product.dart';
import '../models/item_group.dart';
import '../models/store_price.dart';

class GroceryService {
  static const String baseUrl = 'http://192.168.1.111:8000';

  Future<List<GroceryProduct>> demoFetchProducts() async {
    // Mocking an API call
    return const [
      GroceryProduct(itemCode: 1, name: 'AYAM BERSIH - STANDARD', unit: '1 KG'),
      GroceryProduct(itemCode: 2, name: '100 PLUS (ORIGINAL)', unit: '1.5 L'),
      GroceryProduct(itemCode: 3, name: 'ANGGUR HIJAU BERBIJI', unit: '1 KG'),
      GroceryProduct(itemCode: 4, name: 'TIMUN', unit: '1 KG'),
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
}
