import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class OptimizationService {
  final String baseUrl = ApiConstants.baseUrl;
  void Function(int)? onResponseStatus;

  OptimizationService({this.onResponseStatus});

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onResponseStatus?.call(401);
    }
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
