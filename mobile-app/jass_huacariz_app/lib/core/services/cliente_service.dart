import '../config/api_config.dart';
import 'api_service.dart';

class ClienteService {
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

  Future<List<Map<String, dynamic>>> listarClientes() async {
    final response = await _api.get(ApiConfig.clientes);
    return _asList(response);
  }

  Future<Map<String, dynamic>> registrarCliente(
    Map<String, dynamic> data,
  ) async {
    final dni = (data['dni'] ?? '').toString().trim();

    final payload = {
      ...data,
      'dni': dni,
      'nombres': (data['nombres'] ?? '').toString().trim(),
      'apellidos': (data['apellidos'] ?? '').toString().trim(),
      'telefono': (data['telefono'] ?? '').toString().trim(),
      'correo': (data['correo'] ?? '').toString().trim(),

      // Regla del sistema:
      // usuario = DNI
      // contraseña inicial = DNI
      // el backend debe encriptarla
      'codigoUsuario': (data['codigoUsuario'] ?? dni).toString().trim(),
      'password': (data['password'] ?? dni).toString().trim(),
      'rol': data['rol'] ?? 'CLIENTE',
      'estado': data['estado'] ?? true,

      // Cliente con uno o varios suministros
      'suministros': data['suministros'] ?? [],
    };

    final response = await _api.post(ApiConfig.clientes, payload);
    return _asMap(response);
  }

  Future<Map<String, dynamic>> obtenerClientePorId(int idCliente) async {
    final response = await _api.get(ApiConfig.clientePorId(idCliente));
    return _asMap(response);
  }

  Future<List<Map<String, dynamic>>> listarSuministrosPorCliente(
    int idCliente,
  ) async {
    final response = await _api.get(
      ApiConfig.suministrosPorCliente(idCliente),
    );

    return _asList(response);
  }

  Future<Map<String, dynamic>> cambiarEstadoCliente({
    required int idCliente,
    required bool estado,
  }) async {
    final response = await _api.patch(
      '${ApiConfig.clientePorId(idCliente)}/estado?estado=$estado',
      {},
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> cambiarEstadoSuministro({
    required int idCliente,
    required int idSuministro,
    required bool estado,
  }) async {
    final response = await _api.patch(
      '${ApiConfig.suministrosPorCliente(idCliente)}/$idSuministro/estado?estado=$estado',
      {},
    );

    return _asMap(response);
  }
}