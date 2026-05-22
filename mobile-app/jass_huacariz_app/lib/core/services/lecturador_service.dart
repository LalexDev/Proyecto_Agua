import '../config/api_config.dart';
import 'api_service.dart';

class LecturadorService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> buscarSuministro(String codigoSuministro) async {
    final response = await _api.get(ApiConfig.buscarSuministroLecturador(codigoSuministro));
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {};
  }

  Future<Map<String, dynamic>> registrarLectura({
    required String codigoSuministro,
    required int anio,
    required int mes,
    required double lecturaActual,
    String observacion = '',
  }) async {
    final response = await _api.post(ApiConfig.registrarLectura, {
      'codigoSuministro': codigoSuministro,
      'anio': anio,
      'mes': mes,
      'lecturaActual': lecturaActual,
      'observacion': observacion,
    });
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {};
  }
}
