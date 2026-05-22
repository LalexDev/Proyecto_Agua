import '../config/api_config.dart';
import 'api_service.dart';

class TarifaService {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _asList(dynamic response) {
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

  Future<List<Map<String, dynamic>>> listarTarifas() async {
    return _asList(await _api.get(ApiConfig.tarifas));
  }

  Future<Map<String, dynamic>> registrarTarifa(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.tarifas, data);
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {};
  }

  Future<Map<String, dynamic>> actualizarTarifa(int id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.tarifas}/$id', data);
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {};
  }

  Future<Map<String, dynamic>> cambiarEstadoTarifa({required int id, required bool estado}) async {
    final response = await _api.patch('${ApiConfig.tarifas}/$id/estado?estado=$estado', {});
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {};
  }

  Future<void> eliminarTarifa(int id) async {
    await _api.delete('${ApiConfig.tarifas}/$id');
  }
}
