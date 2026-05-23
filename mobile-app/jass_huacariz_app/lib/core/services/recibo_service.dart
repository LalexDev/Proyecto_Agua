import '../config/api_config.dart';
import 'api_service.dart';

class ReciboService {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item)).toList();
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

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return {};
  }

  // =========================
  // CLIENTE
  // =========================

  Future<List<Map<String, dynamic>>> listarMisRecibos() async {
    final response = await _api.get(ApiConfig.clienteRecibos);
    return _asList(response);
  }

  Future<Map<String, dynamic>?> obtenerMiReciboPorId(int idRecibo) async {
    final recibos = await listarMisRecibos();

    for (final recibo in recibos) {
      final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];
      final id = value is int ? value : int.tryParse(value.toString()) ?? 0;

      if (id == idRecibo) {
        return recibo;
      }
    }

    return null;
  }

  // =========================
  // ADMIN
  // =========================

  Future<List<Map<String, dynamic>>> listarRecibosAdmin() async {
    final response = await _api.get(ApiConfig.recibos);
    return _asList(response);
  }

  Future<List<Map<String, dynamic>>> listarPendientesAdmin() async {
    final response = await _api.get(ApiConfig.recibosPendientes);
    return _asList(response);
  }

  Future<List<Map<String, dynamic>>> buscarPorSuministroAdmin(
    String codigoSuministro,
  ) async {
    final response = await _api.get(
      ApiConfig.recibosPorSuministro(codigoSuministro),
    );

    return _asList(response);
  }

  Future<Map<String, dynamic>> pagarReciboAdmin({
    required int idRecibo,
    required String metodoPago,
    required String codigoOperacion,
  }) async {
    final response = await _api.patch(
      ApiConfig.pagarReciboAdmin(idRecibo),
      {
        'metodoPago': metodoPago,
        'codigoOperacion': codigoOperacion,
      },
    );

    return _asMap(response);
  }
}