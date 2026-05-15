import '../config/api_config.dart';
import 'api_service.dart';

class PagoService {
  final ApiService _apiService = ApiService();

  final bool usarDatosPrueba = true;

  Future<Map<String, dynamic>> generarCodigoPago({
    required int idRecibo,
    required String metodoPago,
    required double monto,
  }) async {
    if (usarDatosPrueba) {
      await Future.delayed(const Duration(milliseconds: 600));

      final numero = DateTime.now().millisecondsSinceEpoch % 1000000000;

      String codigo;

      if (metodoPago == 'PagoEfectivo') {
        codigo = 'CIP-$numero';
      } else if (metodoPago == 'Transferencia') {
        codigo = 'TR-$numero';
      } else {
        codigo = 'PRES-$numero';
      }

      return {
        'idRecibo': idRecibo,
        'metodoPago': metodoPago,
        'codigoOperacion': codigo,
        'monto': monto,
        'estado': 'Generado',
      };
    }

    final response = await _apiService.post(
      '${ApiConfig.pagos}/generar',
      {
        'idRecibo': idRecibo,
        'metodoPago': metodoPago,
        'monto': monto,
      },
    );

    return Map<String, dynamic>.from(response);
  }

  Future<bool> confirmarPago({
    required int idRecibo,
    required String codigoOperacion,
  }) async {
    if (usarDatosPrueba) {
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }

    await _apiService.post(
      '${ApiConfig.pagos}/confirmar',
      {
        'idRecibo': idRecibo,
        'codigoOperacion': codigoOperacion,
      },
    );

    return true;
  }
}