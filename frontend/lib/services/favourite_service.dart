import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grocery_product.dart';
import '../constants/api_constants.dart';

class FavouriteService {
  final String baseUrl = ApiConstants.baseUrl;
  void Function(int)? onResponseStatus;

  FavouriteService({this.onResponseStatus});

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onResponseStatus?.call(401);
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

  Future<Map<String, dynamic>> fetchFavouritesWorthBuying({
    required String token,
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final queryParams = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius_km': radiusKm.toString(),
    };
    final url = Uri.parse('$baseUrl/favourites/worth_buying').replace(queryParameters: queryParams);
    
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
      throw Exception('Failed to fetch favourites worth buying');
    }
  }
}
