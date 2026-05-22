import '../config/api_config.dart';
import 'api_service.dart';

class ReciboService {
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

  Future<List<Map<String, dynamic>>> listarMisRecibos() async {
    return _asList(await _api.get(ApiConfig.clienteRecibos));
  }

  Future<Map<String, dynamic>?> obtenerMiReciboPorId(int idRecibo) async {
    final recibos = await listarMisRecibos();
    for (final recibo in recibos) {
      final id = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];
      if (id.toString() == idRecibo.toString()) return recibo;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> listarRecibosAdmin() async {
    return _asList(await _api.get(ApiConfig.recibos));
  }

  Future<List<Map<String, dynamic>>> listarPendientesAdmin() async {
    return _asList(await _api.get(ApiConfig.recibosPendientes));
  }

  Future<List<Map<String, dynamic>>> buscarPorSuministro(String codigoSuministro) async {
    return _asList(await _api.get(ApiConfig.recibosPorSuministro(codigoSuministro)));
  }

  Future<Map<String, dynamic>> pagarReciboAdmin({
    required int idRecibo,
    required String metodoPago,
    required String codigoOperacion,
  }) async {
    final response = await _api.patch(ApiConfig.pagarReciboAdmin(idRecibo), {
      'metodoPago': metodoPago,
      'codigoOperacion': codigoOperacion,
    });
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'mensaje': 'Pago registrado correctamente'};
  }
}
