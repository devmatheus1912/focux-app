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
    final isAdmin = response.data['isAdmin'] as bool? ?? false;
    await SecureStorage.saveToken(token);
    await SecureStorage.saveRole('PERSONAL');
    await SecureStorage.saveIsAdmin(isAdmin);
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
    await SecureStorage.saveRole('PERSONAL');
    await SecureStorage.saveIsAdmin(false);
    return token;
  }

  Future<String> loginAluno(String email, String password) async {
    final response = await _dio.post('/api/auth/login/aluno', data: {
      'email': email,
      'senha': password,
    });
    final token = response.data['token'] as String;
    await SecureStorage.saveToken(token);
    await SecureStorage.saveRole('ALUNO');
    return token;
  }

  Future<String> registerAluno(String nome, String email, String password, String conviteToken) async {
    final response = await _dio.post('/api/auth/register/aluno', data: {
      'nome': nome,
      'email': email,
      'senha': password,
      'conviteToken': conviteToken,
    });
    final token = response.data['token'] as String;
    await SecureStorage.saveToken(token);
    await SecureStorage.saveRole('ALUNO');
    return token;
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    await SecureStorage.deleteRole();
    await SecureStorage.deleteIsAdmin();
  }
}
