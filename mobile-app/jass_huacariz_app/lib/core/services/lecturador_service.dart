import '../config/api_config.dart';
import 'api_service.dart';

class LecturadorService {
  final ApiService _api = ApiService();

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return {};
  }

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (response is Map && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (response is Map && response['content'] is List) {
      return (response['content'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> buscarSuministro(
    String codigoSuministro,
  ) async {
    final codigo = codigoSuministro.trim().toUpperCase();

    final response = await _api.get(
      ApiConfig.buscarSuministroLecturador(codigo),
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> buscarPorCodigo(
    String codigoSuministro,
  ) async {
    return buscarSuministro(codigoSuministro);
  }

  Future<Map<String, dynamic>> buscarSuministroPorCodigo(
    String codigoSuministro,
  ) async {
    return buscarSuministro(codigoSuministro);
  }

  Future<List<Map<String, dynamic>>>
      listarSuministrosOffline() async {
    final response = await _api.get(
      ApiConfig.suministrosOfflineLecturador,
    );

    return _asList(response);
  }

  Future<Map<String, dynamic>> registrarLectura({
    required String codigoSuministro,
    required double lecturaActual,
    required int anio,
    required int mes,
    String? observacion,
    String? idOperacionCliente,
  }) async {
    final payload = {
      'codigoSuministro':
          codigoSuministro.trim().toUpperCase(),
      'lecturaActual': lecturaActual,
      'anio': anio,
      'mes': mes,
      'observacion': observacion?.trim() ?? '',
      if (idOperacionCliente != null &&
          idOperacionCliente.trim().isNotEmpty)
        'idOperacionCliente':
            idOperacionCliente.trim(),
    };

    final response = await _api.post(
      ApiConfig.registrarLectura,
      payload,
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> registrarLecturaPayload(
    Map<String, dynamic> data,
  ) async {
    final fechaActual = DateTime.now();

    final payload = {
      'codigoSuministro':
          (data['codigoSuministro'] ?? '')
              .toString()
              .trim()
              .toUpperCase(),
      'lecturaActual': data['lecturaActual'],
      'anio': data['anio'] ?? fechaActual.year,
      'mes': data['mes'] ?? fechaActual.month,
      'observacion':
          (data['observacion'] ?? '')
              .toString()
              .trim(),
      if (data['idOperacionCliente'] != null)
        'idOperacionCliente':
            data['idOperacionCliente']
                .toString()
                .trim(),
    };

    final response = await _api.post(
      ApiConfig.registrarLectura,
      payload,
    );

    return _asMap(response);
  }

  Future<List<Map<String, dynamic>>> listarHistorialLocal() async {
    return [];
  }
}
