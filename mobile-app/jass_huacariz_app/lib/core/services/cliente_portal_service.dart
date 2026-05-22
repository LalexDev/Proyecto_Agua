import '../config/api_config.dart';
import 'api_service.dart';

class ClientePortalService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> obtenerMiPerfil() async {
    final response = await _api.get(ApiConfig.clientePerfil);

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return {};
  }

  Future<List<Map<String, dynamic>>> listarMisSuministros() async {
    final response = await _api.get(ApiConfig.clienteSuministros);

    if (response is List) {
      return response.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    if (response is Map && response['data'] is List) {
      return (response['data'] as List).map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    if (response is Map && response['content'] is List) {
      return (response['content'] as List).map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
    required String confirmarPassword,
  }) async {
    final response = await _api.patch(
      ApiConfig.clienteCambiarPassword,
      {
        'passwordActual': passwordActual,
        'nuevaPassword': nuevaPassword,
        'confirmarPassword': confirmarPassword,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return {
      'mensaje': 'Contraseña actualizada correctamente',
    };
  }
}