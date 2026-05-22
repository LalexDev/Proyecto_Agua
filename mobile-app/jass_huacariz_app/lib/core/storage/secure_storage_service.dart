import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _tokenKey = 'token';
  static const String _roleKey = 'rol';
  static const String _userKey = 'codigoUsuario';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUserRole(String rol) async {
    await _storage.write(key: _roleKey, value: rol);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<void> saveUserName(String codigoUsuario) async {
    await _storage.write(key: _userKey, value: codigoUsuario);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _userKey);
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}