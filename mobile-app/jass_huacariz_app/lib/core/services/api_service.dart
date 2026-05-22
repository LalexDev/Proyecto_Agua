import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class ApiService {
  final SecureStorageService _storage = SecureStorageService();

  static const Duration _timeout = Duration(seconds: 15);

  Uri _uri(String endpoint) {
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
    try {
      final response = await http
          .get(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
  throw Exception(e.toString().replaceFirst('Exception: ', ''));
}
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
  throw Exception(e.toString().replaceFirst('Exception: ', ''));
}
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .put(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
  throw Exception(e.toString().replaceFirst('Exception: ', ''));
}
  }

  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .patch(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
  throw Exception(e.toString().replaceFirst('Exception: ', ''));
}
  }

  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    try {
      final response = await http
          .delete(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
  throw Exception(e.toString().replaceFirst('Exception: ', ''));
}
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        return null;
      }

      throw Exception('Error HTTP $statusCode');
    }

    final decoded = jsonDecode(body);

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    if (decoded is Map && decoded['mensaje'] != null) {
      throw Exception(decoded['mensaje']);
    }

    if (decoded is Map && decoded['message'] != null) {
      throw Exception(decoded['message']);
    }

    if (decoded is Map && decoded['error'] != null) {
      throw Exception(decoded['error']);
    }

    throw Exception('Error HTTP $statusCode');
  }
}