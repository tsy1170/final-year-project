import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/complaint.dart';
import '../constants/api_constants.dart';

class ComplaintService {
  Future<Map<String, dynamic>> createComplaint(String token, Complaint complaint) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/complaints'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add all complaint fields as individual form fields
    final fields = complaint.toFormFields();
    fields.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Add attachments
    for (var file in complaint.attachments) {
      String extension = file.path.split('.').last.toLowerCase();
      MediaType contentType;
      
      // Map extensions to the correct MediaType expected by the server
      if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        // Default to jpeg for camera photos (usually .jpg or .jpeg)
        contentType = MediaType('image', 'jpeg');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'attachments',
        file.path,
        contentType: contentType,
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      String message;
      try {
        final error = json.decode(response.body);
        message = error['detail']?.toString() ?? 'Failed to save complaint';
      } catch (_) {
        message = 'Server error (${response.statusCode}): ${response.body}';
      }
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getComplaints(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/complaints'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch complaints');
    }
  }

  Future<Map<String, dynamic>> deleteComplaints(String token, List<int> complaintIds) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/complaints'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'complaint_ids': complaintIds,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete complaints');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyPremises(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/premises/nearby?latitude=$lat&longitude=$lng'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['premises'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch nearby premises');
    }
  }
}
