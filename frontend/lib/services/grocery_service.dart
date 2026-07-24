import '../models/grocery_product.dart';

class GroceryService {
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
}
