import '../models/grocery_product.dart';

class GroceryService {
  Future<List<GroceryProduct>> fetchProducts() async {
    // Mocking an API call
    return const [
      GroceryProduct(name: 'AYAM BERSIH -\nSTANDARD', unit: '1 KG'),
      GroceryProduct(name: '100 PLUS\n(ORIGINAL)', unit: '1.5 L'),
      GroceryProduct(name: 'ANGGUR HIJAU\nBERBIJI', unit: '1 KG'),
      GroceryProduct(name: 'TIMUN', unit: '1 KG'),
    ];
  }
}
