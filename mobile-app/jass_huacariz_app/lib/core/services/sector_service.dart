import '../config/api_config.dart';
import 'api_service.dart';

class SectorService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> listarSectores() async {
    final response = await _api.get(ApiConfig.sectores);
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (response is Map && response['data'] is List) {
      return (response['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }
}
