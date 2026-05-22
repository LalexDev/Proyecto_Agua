import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  Future<bool> login({
    required String codigoUsuario,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.login,
      {
        'codigoUsuario': codigoUsuario,
        'password': password,
      },
      withAuth: false,
    );

    final token = response['token']?.toString() ?? '';
    final rol = response['rol']?.toString() ?? '';
    final usuario = response['codigoUsuario']?.toString() ?? codigoUsuario;

    if (token.isEmpty) {
      throw Exception('El backend no devolvió token.');
    }

    await _storage.saveToken(token);
    await _storage.saveUserRole(rol);
    await _storage.saveUserName(usuario);

    return true;
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<String?> getRol() async {
    return await _storage.getUserRole();
  }

  Future<String?> getCodigoUsuario() async {
    return await _storage.getUserName();
  }

  Future<bool> estaAutenticado() async {
    return await _storage.hasSession();
  }
}