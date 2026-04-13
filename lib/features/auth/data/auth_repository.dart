import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(ApiClient client) : _dio = client.dio;

  Future<String> loginPersonal(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'senha': password,
    });
    final token = response.data['token'] as String;
    await SecureStorage.saveToken(token);
    return token;
  }

  Future<String> registerPersonal(String nome, String email, String password) async {
    final response = await _dio.post('/api/auth/register/personal', data: {
      'nome': nome,
      'email': email,
      'senha': password,
    });
    final token = response.data['token'] as String;
    await SecureStorage.saveToken(token);
    return token;
  }

  Future<void> logout() => SecureStorage.deleteToken();
}
