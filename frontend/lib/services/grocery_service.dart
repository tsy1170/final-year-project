import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grocery_product.dart';
import '../models/item_group.dart';

class GroceryService {
  final String baseUrl = 'http://192.168.1.107:8000';

  Future<List<GroceryProduct>> fetchProducts() async {
    // Mocking an API call
    return const [
      GroceryProduct(name: 'AYAM BERSIH - STANDARD', unit: '1 KG'),
      GroceryProduct(name: '100 PLUS (ORIGINAL)', unit: '1.5 L'),
      GroceryProduct(name: 'ANGGUR HIJAU BERBIJI', unit: '1 KG'),
      GroceryProduct(name: 'TIMUN', unit: '1 KG'),
      GroceryProduct(name: 'AYAM BERSIH - STANDARD', unit: '1 KG'),
      GroceryProduct(name: '100 PLUS (ORIGINAL)', unit: '1.5 L'),
      GroceryProduct(name: 'ANGGUR HIJAU BERBIJI', unit: '1 KG'),
      GroceryProduct(name: 'TIMUN', unit: '1 KG'),
    ];
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
}
