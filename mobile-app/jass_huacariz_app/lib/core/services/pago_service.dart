import '../config/api_config.dart';
import 'api_service.dart';

class PagoService {
  final ApiService _api = ApiService();

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

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return {};
  }

  Future<List<Map<String, dynamic>>> listarPagos() async {
    final response = await _api.get(ApiConfig.pagos);
    return _asList(response);
  }

  Future<List<Map<String, dynamic>>> buscarPagosPorSuministro(
    String codigoSuministro,
  ) async {
    final response = await _api.get(
      ApiConfig.pagosPorSuministro(codigoSuministro),
    );

    return _asList(response);
  }

  Future<Map<String, dynamic>> pagarMiRecibo({
    required int idRecibo,
    required String metodoPago,
    required String codigoOperacion,
  }) async {
    final response = await _api.patch(
      ApiConfig.pagarReciboCliente(idRecibo),
      {
        'metodoPago': metodoPago,
        'codigoOperacion': codigoOperacion,
      },
    );

    return _asMap(response);
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