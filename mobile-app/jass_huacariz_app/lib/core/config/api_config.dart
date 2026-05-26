class ApiConfig {
  // Android Emulator hacia backend local
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // AUTH
  static const String login = '/auth/login';

  // CLIENTE PORTAL
  static const String clientePerfil = '/cliente/me';
  static const String clienteSuministros = '/cliente/me/suministros';
  static const String clienteRecibos = '/cliente/me/recibos';
  static const String clienteCambiarPassword = '/cliente/me/password';

  static String pagarReciboCliente(int idRecibo) {
    return '/cliente/me/recibos/$idRecibo/pagar';
  }

  // ADMIN CLIENTES
  static const String clientes = '/clientes';

  static String clientePorId(int idCliente) {
    return '/clientes/$idCliente';
  }

  static String suministrosPorCliente(int idCliente) {
    return '/clientes/$idCliente/suministros';
  }

  static String cambiarEstadoCliente(int idCliente, bool estado) {
    return '/clientes/$idCliente/estado?estado=$estado';
  }

  static String cambiarEstadoSuministro({
    required int idCliente,
    required int idSuministro,
    required bool estado,
  }) {
    return '/clientes/$idCliente/suministros/$idSuministro/estado?estado=$estado';
  }

  // ADMIN RECIBOS
  static const String recibos = '/recibos';
  static const String recibosPendientes = '/recibos/pendientes';

  static String recibosPorSuministro(String codigoSuministro) {
    return '/recibos/suministro/$codigoSuministro';
  }

  static String pagarReciboAdmin(int idRecibo) {
    return '/recibos/$idRecibo/pagar';
  }

  // PAGOS
  static const String pagos = '/pagos';

  static String pagosPorSuministro(String codigoSuministro) {
    return '/pagos/suministro/$codigoSuministro';
  }

  // TARIFAS
  static const String tarifas = '/tarifas';

  static String tarifaPorId(int idTarifa) {
    return '/tarifas/$idTarifa';
  }

  static String cambiarEstadoTarifa(int idTarifa, bool estado) {
    return '/tarifas/$idTarifa/estado?estado=$estado';
  }

  // SECTORES
  static const String sectores = '/sectores';

  // LECTURADOR
  static String buscarSuministroLecturador(String codigoSuministro) {
    return '/lecturador/suministros/$codigoSuministro';
  }

  static const String registrarLectura = '/lecturador/lecturas';

  // ADMIN HISTORIAL LECTURAS
  static const String historialLecturasAdmin = '/admin/lecturas/historial';
}