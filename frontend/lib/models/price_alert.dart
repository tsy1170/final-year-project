class PriceAlert {
  final int alertId;
  final int itemCode;
  final double target_price;
  final bool isActive;
  final DateTime createdAt;
  final String itemName;
  final String unit;
  final String? imagePath;
  final String? imageUrl;

  PriceAlert({
    required this.alertId,
    required this.itemCode,
    required this.target_price,
    required this.isActive,
    required this.createdAt,
    required this.itemName,
    required this.unit,
    this.imagePath,
    this.imageUrl,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      alertId: json['alert_id'],
      itemCode: json['item_code'],
      target_price: (json['target_price'] as num).toDouble(),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      itemName: json['item_name'],
      unit: json['unit'],
      imagePath: json['image_path'],
      imageUrl: json['image_url'],
    );
  }
}
