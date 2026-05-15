import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class ApiService {
  final SecureStorageService _storage = SecureStorageService();

  Uri _buildUri(String endpoint) {
    return Uri.parse('${ApiConfig.baseUrl}$endpoint');
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await _storage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    final response = await http.get(
      _buildUri(endpoint),
      headers: await _headers(withAuth: withAuth),
    );

    return _processResponse(response);
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.post(
      _buildUri(endpoint),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );

    return _processResponse(response);
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.put(
      _buildUri(endpoint),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );

    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    final response = await http.delete(
      _buildUri(endpoint),
      headers: await _headers(withAuth: withAuth),
    );

    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (response.body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        return null;
      }

      throw Exception('Error HTTP $statusCode');
    }

    final decodedBody = jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return decodedBody;
    }

    final message = decodedBody is Map && decodedBody['message'] != null
        ? decodedBody['message']
        : 'Error HTTP $statusCode';

    throw Exception(message);
  }
}