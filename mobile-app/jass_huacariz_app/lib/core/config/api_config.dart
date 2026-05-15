class ApiConfig {
  // Backend local usando emulador Android
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // Si corres en Chrome, puedes cambiar temporalmente a:
  // static const String baseUrl = 'http://localhost:8080/api';

  static const String login = '/auth/login';
  static const String perfil = '/clientes/perfil';
  static const String recibos = '/recibos';
  static const String pagos = '/pagos';
  static const String cambiarPassword = '/auth/cambiar-password';
}