class StorePrice {
  final int premiseCode;
  final String premiseName;
  final String address;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final double distance;
  final double price;
  final String priceDate;
  final String priceLevel;

  StorePrice({
    required this.premiseCode,
    required this.premiseName,
    required this.address,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.price,
    required this.priceDate,
    required this.priceLevel,
  });

  factory StorePrice.fromJson(Map<String, dynamic> json) {
    return StorePrice(
      premiseCode: json['premise_code'] as int,
      premiseName: json['premise_name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      state: json['state'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['road_distance_km'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      priceDate: json['price_date'] as String,
      priceLevel: json['price_level'] as String,
    );
  }
}
