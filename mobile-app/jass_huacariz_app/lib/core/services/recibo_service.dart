import '../config/api_config.dart';
import 'api_service.dart';

class ReciboService {
  final ApiService _apiService = ApiService();

  final bool usarDatosPrueba = true;

  Future<List<Map<String, dynamic>>> listarMisRecibos() async {
    if (usarDatosPrueba) {
      await Future.delayed(const Duration(milliseconds: 500));

      return [
        {
          'id': 1,
          'codigo': 'REC-0001',
          'suministro': 'Casa principal',
          'direccion': 'Av. Principal 123',
          'periodo': 'Mayo 2026',
          'consumo': 12,
          'total': 37.00,
          'vencimiento': '15/05/2026',
          'estado': 'Pendiente',
        },
        {
          'id': 2,
          'codigo': 'REC-0002',
          'suministro': 'Tienda',
          'direccion': 'Av. Principal 125',
          'periodo': 'Mayo 2026',
          'consumo': 18,
          'total': 91.00,
          'vencimiento': '15/05/2026',
          'estado': 'Pagado',
        },
        {
          'id': 3,
          'codigo': 'REC-0003',
          'suministro': 'Local comercial',
          'direccion': 'Jr. Lima 560',
          'periodo': 'Mayo 2026',
          'consumo': 10,
          'total': 31.00,
          'vencimiento': '15/05/2026',
          'estado': 'Pendiente',
        },
        {
          'id': 4,
          'codigo': 'REC-0004',
          'suministro': 'Casa principal',
          'direccion': 'Av. Principal 123',
          'periodo': 'Abril 2026',
          'consumo': 12,
          'total': 37.00,
          'vencimiento': '15/04/2026',
          'estado': 'Pagado',
        },
      ];
    }

    final response = await _apiService.get(ApiConfig.recibos);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> obtenerDetalleRecibo(int id) async {
    if (usarDatosPrueba) {
      await Future.delayed(const Duration(milliseconds: 400));

      return {
        'id': id,
        'codigo': 'REC-000$id',
        'suministro': 'Casa principal',
        'direccion': 'Av. Principal 123',
        'periodo': 'Mayo 2026',
        'lecturaAnterior': 450.345,
        'lecturaActual': 462.345,
        'consumo': 12,
        'subtotal': 36.00,
        'pagoLector': 1.00,
        'mantenimiento': 0.00,
        'mora': 0.00,
        'total': 37.00,
        'vencimiento': '15/05/2026',
        'estado': 'Pendiente',
      };
    }

    final response = await _apiService.get('${ApiConfig.recibos}/$id');

    return Map<String, dynamic>.from(response);
  }
}