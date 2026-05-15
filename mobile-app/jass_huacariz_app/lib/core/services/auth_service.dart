import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  final bool usarDatosPrueba = true;

  Future<bool> login({
    required String usuario,
    required String password,
  }) async {
    if (usarDatosPrueba) {
      await Future.delayed(const Duration(milliseconds: 700));

      if (usuario == '12345678' && password == '123456') {
        await _storage.saveToken('TOKEN_DE_PRUEBA_JASS_HUACARIZ');
        await _storage.saveUserRole('CLIENTE');
        await _storage.saveUserName('Dany Carmona');
        return true;
      }

      return false;
    }

    final response = await _apiService.post(
      ApiConfig.login,
      {
        'usuario': usuario,
        'password': password,
      },
      withAuth: false,
    );

    final token = response['token'];
    final role = response['role'];
    final nombre = response['nombre'];

    await _storage.saveToken(token);
    await _storage.saveUserRole(role);
    await _storage.saveUserName(nombre);

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
    if (usarDatosPrueba) {
      await Future.delayed(const Duration(milliseconds: 700));
      return true;
    }

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