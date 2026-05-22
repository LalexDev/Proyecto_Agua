import '../config/api_config.dart';
import 'api_service.dart';

class PagoService {
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

  Future<Map<String, dynamic>> pagarMiRecibo({
    required int idRecibo,
    required String metodoPago,
    required String codigoOperacion,
  }) async {
    final response = await _api.patch(ApiConfig.pagarReciboCliente(idRecibo), {
      'metodoPago': metodoPago,
      'codigoOperacion': codigoOperacion,
    });
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'mensaje': 'Pago registrado correctamente'};
  }

  Future<List<Map<String, dynamic>>> listarPagos() async {
    return _asList(await _api.get(ApiConfig.pagos));
  }

  Future<List<Map<String, dynamic>>> buscarPorSuministro(String codigoSuministro) async {
    return _asList(await _api.get(ApiConfig.pagosPorSuministro(codigoSuministro)));
  }
}
