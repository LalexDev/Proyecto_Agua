import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  Future<bool> login({
    required String usuario,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.login,
      {
        'usuario': usuario,
        'password': password,
      },
      withAuth: false,
    );

    final token = response['token'] ??
        response['accessToken'] ??
        response['jwt'] ??
        '';

    final role = response['role'] ??
        response['rol'] ??
        response['tipoUsuario'] ??
        response['authority'] ??
        '';

    final nombre = response['nombre'] ??
        response['nombres'] ??
        response['username'] ??
        response['usuario'] ??
        usuario;

    if (token.toString().isEmpty) {
      throw Exception('El backend no devolvió token.');
    }

    await _storage.saveToken(token.toString());
    await _storage.saveUserRole(role.toString());
    await _storage.saveUserName(nombre.toString());

    return true;
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() async {
    return await _storage.hasSession();
  }

  Future<String?> getUserName() async {
    return await _storage.getUserName();
  }

  Future<String?> getUserRole() async {
    return await _storage.getUserRole();
  }

  Future<bool> cambiarPassword({
    required String actual,
    required String nueva,
  }) async {
    await _apiService.put(
      ApiConfig.cambiarPassword,
      {
        'passwordActual': actual,
        'passwordNueva': nueva,
      },
    );

    return true;
  }
}