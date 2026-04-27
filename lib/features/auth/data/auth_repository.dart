import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class PasswordResetRequestResult {
  final String mensagem;
  final bool deliveryAvailable;

  const PasswordResetRequestResult({
    required this.mensagem,
    required this.deliveryAvailable,
  });

  factory PasswordResetRequestResult.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequestResult(
      mensagem: json['mensagem'] as String? ??
          'Se o e-mail estiver cadastrado, voce recebera as instrucoes.',
      deliveryAvailable: json['deliveryAvailable'] as bool? ?? true,
    );
  }
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(ApiClient client) : _dio = client.dio;

  Future<String> loginPersonal(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'senha': password,
    });
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String?;
    final isAdmin = response.data['isAdmin'] as bool? ?? false;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) await SecureStorage.saveRefreshToken(refreshToken);
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
    final refreshToken = response.data['refreshToken'] as String?;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveRole('PERSONAL');
    await SecureStorage.saveIsAdmin(false);
    return token;
  }

  Future<bool> loginAluno(String email, String password) async {
    final response = await _dio.post('/api/auth/login/aluno', data: {
      'email': email,
      'senha': password,
    });
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String?;
    final requiresPasswordChange =
        response.data['requiresPasswordChange'] as bool? ?? false;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveRole('ALUNO');
    await SecureStorage.saveRequiresPasswordChange(requiresPasswordChange);
    return requiresPasswordChange;
  }

  Future<String> registerAluno(String nome, String email, String password, String conviteToken, {String? personalSlug}) async {
    final requestBody = <String, dynamic>{
      'nome': nome,
      'email': email,
      'senha': password,
      'conviteToken': conviteToken,
    };
    if (personalSlug != null) requestBody['personalSlug'] = personalSlug;
    final response = await _dio.post('/api/auth/register/aluno', data: requestBody);
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String?;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveRole('ALUNO');
    await SecureStorage.saveRequiresPasswordChange(false);
    return token;
  }

  Future<void> definirSenhaDefinitivaAluno(
      String senhaAtual, String novaSenha) async {
    await _dio.post('/api/auth/aluno/definir-senha', data: {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
    });
    await SecureStorage.saveRequiresPasswordChange(false);
  }

  Future<PasswordResetRequestResult> solicitarResetSenha({
    required String email,
    required bool isAluno,
  }) async {
    final response = await _dio.post('/api/auth/esqueci-senha', data: {
      'email': email,
      'tipo': isAluno ? 'ALUNO' : 'PERSONAL',
    });
    return PasswordResetRequestResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }
}
