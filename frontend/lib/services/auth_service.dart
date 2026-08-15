import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://192.168.1.111:8000';
  void Function(int)? onResponseStatus;

  AuthService({this.onResponseStatus});

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onResponseStatus?.call(401);
    }
  }

  Future<bool> register({
    required String userName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'email': email,
        'password': password,
      }),
    );
    _handleResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      String errorMessage = 'Registration failed';
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (errorData['detail'] != null) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        // Fallback
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );
    _handleResponse(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      String errorMessage = 'Login failed';
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (errorData['detail'] != null) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        // Fallback
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final url = Uri.parse('$baseUrl/users/me');
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
      throw Exception('Failed to fetch current user');
    }
  }
}
