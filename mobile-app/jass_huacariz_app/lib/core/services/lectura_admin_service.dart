import '../config/api_config.dart';
import 'api_service.dart';

class LecturaAdminService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> listarHistorial() async {
    final response = await _api.get(ApiConfig.historialLecturasAdmin);
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (response is Map && response['data'] is List) {
      return (response['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (response is Map && response['content'] is List) {
      return (response['content'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }
}
