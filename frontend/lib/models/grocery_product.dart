class GroceryProduct {
  final int itemCode;
  final String name;
  final String unit;
  final String? imageUrl;

  const GroceryProduct({
    required this.itemCode,
    required this.name,
    required this.unit,
    this.imageUrl,
  });

  factory GroceryProduct.fromJson(Map<String, dynamic> json) {
    return GroceryProduct(
      itemCode: json['item_code'] as int,
      name: json['item_name'] as String,
      unit: json['unit'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}
