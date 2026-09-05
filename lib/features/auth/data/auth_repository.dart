import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/fcm/fcm_service.dart';
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
      mensagem:
          json['mensagem'] as String? ??
          'Se o e-mail estiver cadastrado, voce recebera as instrucoes.',
      deliveryAvailable: json['deliveryAvailable'] as bool? ?? true,
    );
  }
}

class AuthCapabilities {
  final bool passwordResetEmailAvailable;
  final bool googleSignInEnabled;
  final bool appleSignInEnabled;

  const AuthCapabilities({
    required this.passwordResetEmailAvailable,
    required this.googleSignInEnabled,
    required this.appleSignInEnabled,
  });

  factory AuthCapabilities.fromJson(Map<String, dynamic> json) {
    return AuthCapabilities(
      passwordResetEmailAvailable:
          json['passwordResetEmailAvailable'] as bool? ?? false,
      googleSignInEnabled: json['googleSignInEnabled'] as bool? ?? false,
      appleSignInEnabled: json['appleSignInEnabled'] as bool? ?? false,
    );
  }
}

class EnviarCodigoEmailResult {
  final String status;
  final bool codigoEnviado;
  final String hint;

  const EnviarCodigoEmailResult({
    required this.status,
    required this.codigoEnviado,
    required this.hint,
  });

  factory EnviarCodigoEmailResult.fromJson(Map<String, dynamic> json) {
    return EnviarCodigoEmailResult(
      status:
          json['status'] as String? ??
          'Se o e-mail for válido, você receberá um código.',
      codigoEnviado: json['codigoEnviado'] as bool? ?? true,
      hint: json['hint'] as String? ?? '',
    );
  }
}

class AuthEnvironmentIssue {
  final String area;
  final String severity;
  final String title;
  final String detail;
  final String action;

  const AuthEnvironmentIssue({
    required this.area,
    required this.severity,
    required this.title,
    required this.detail,
    required this.action,
  });

  factory AuthEnvironmentIssue.fromJson(Map<String, dynamic> json) {
    return AuthEnvironmentIssue(
      area: json['area'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      title: json['title'] as String? ?? 'Configuracao pendente',
      detail: json['detail'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }
}

class AuthEnvironmentStatus {
  final String status;
  final bool productionReady;
  final bool passwordResetReady;
  final bool googleSignInReady;
  final bool googleSignInEnabled;
  final bool googleClientIdsConfigured;
  final List<String> missing;
  final List<AuthEnvironmentIssue> issues;
  final List<String> nextActions;

  const AuthEnvironmentStatus({
    required this.status,
    required this.productionReady,
    required this.passwordResetReady,
    required this.googleSignInReady,
    required this.googleSignInEnabled,
    required this.googleClientIdsConfigured,
    required this.missing,
    required this.issues,
    required this.nextActions,
  });

  factory AuthEnvironmentStatus.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'];
    final rawActions = json['nextActions'];
    final rawMissing = json['missing'];
    return AuthEnvironmentStatus(
      status: json['status'] as String? ?? 'UNKNOWN',
      productionReady: json['productionReady'] as bool? ?? false,
      passwordResetReady: json['passwordResetReady'] as bool? ?? false,
      googleSignInReady: json['googleSignInReady'] as bool? ?? false,
      googleSignInEnabled: json['googleSignInEnabled'] as bool? ?? false,
      googleClientIdsConfigured:
          json['googleClientIdsConfigured'] as bool? ?? false,
      missing:
          rawMissing is List
              ? rawMissing.map((item) => item.toString()).toList()
              : const [],
      issues:
          rawIssues is List
              ? rawIssues
                  .whereType<Map>()
                  .map(
                    (item) => AuthEnvironmentIssue.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList()
              : const [],
      nextActions:
          rawActions is List
              ? rawActions.map((item) => item.toString()).toList()
              : const [],
    );
  }

  AuthEnvironmentIssue? firstIssueFor(String area) {
    for (final issue in issues) {
      if (issue.area == area) return issue;
    }
    return null;
  }
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(ApiClient client) : _dio = client.dio;

  Future<AuthCapabilities> capabilities() async {
    final response = await _dio.get('/api/auth/capabilities');
    return AuthCapabilities.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthEnvironmentStatus> environmentStatus() async {
    final response = await _dio.get('/api/auth/environment-status');
    return AuthEnvironmentStatus.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<String> loginPersonal(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'senha': password},
    );
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String?;
    final isAdmin = response.data['isAdmin'] as bool? ?? false;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveRole('PERSONAL');
    await SecureStorage.saveIsAdmin(isAdmin);
    return token;
  }

  Future<String> registerPersonal(
    String nome,
    String email,
    String password, {
    String? referralCodigo,
    String? telefone,
    String? emailCodigo,
  }) async {
    final response = await _dio.post(
      '/api/auth/register/personal',
      data: {
        'nome': nome,
        'email': email,
        'senha': password,
        if (referralCodigo != null && referralCodigo.isNotEmpty)
          'referralCodigo': referralCodigo,
        if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
        if (emailCodigo != null && emailCodigo.isNotEmpty)
          'emailCodigo': emailCodigo,
      },
    );
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String?;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveRole('PERSONAL');
    await SecureStorage.saveIsAdmin(false);
    return token;
  }

  Future<EnviarCodigoEmailResult> enviarCodigoEmail(String email) async {
    final response = await _dio.post(
      '/api/auth/email/enviar-codigo',
      data: {'email': email},
    );
    return EnviarCodigoEmailResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<bool> loginAluno(String email, String password, {String? personalSlug}) async {
    final data = <String, dynamic>{
      'email': email,
      'senha': password,
    };
    if (personalSlug != null && personalSlug.trim().isNotEmpty) {
      data['personalSlug'] = personalSlug.trim();
    }
    final response = await _dio.post('/api/auth/login/aluno', data: data);
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String?;
    final requiresPasswordChange =
        response.data['requiresPasswordChange'] as bool? ?? false;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveRole('ALUNO');
    await SecureStorage.saveRequiresPasswordChange(requiresPasswordChange);
    return requiresPasswordChange;
  }

  Future<void> loginGoogle({
    required String idToken,
    required bool isAluno,
    String? personalSlug,
  }) async {
    final data = <String, dynamic>{
      'idToken': idToken,
      'role': isAluno ? 'ALUNO' : 'PERSONAL',
    };
    if (isAluno && personalSlug != null && personalSlug.trim().isNotEmpty) {
      data['personalSlug'] = personalSlug.trim();
    }
    final response = await _dio.post('/api/auth/google', data: data);
    await _persistAuthResponse(
      response.data as Map<String, dynamic>,
      fallbackRole: isAluno ? 'ALUNO' : 'PERSONAL',
    );
  }

  /// Sign in with Apple — `POST /api/auth/apple`.
  Future<void> loginApple({
    required String identityToken,
    required bool isAluno,
    String? fullName,
    String? email,
    String? personalSlug,
  }) async {
    final data = <String, dynamic>{
      'identityToken': identityToken,
      'role': isAluno ? 'ALUNO' : 'PERSONAL',
      if (fullName != null && fullName.trim().isNotEmpty)
        'fullName': fullName.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };
    if (isAluno && personalSlug != null && personalSlug.trim().isNotEmpty) {
      data['personalSlug'] = personalSlug.trim();
    }
    final response = await _dio.post('/api/auth/apple', data: data);
    await _persistAuthResponse(
      response.data as Map<String, dynamic>,
      fallbackRole: isAluno ? 'ALUNO' : 'PERSONAL',
    );
  }

  Future<void> _persistAuthResponse(
    Map<String, dynamic> body, {
    required String fallbackRole,
  }) async {
    final token = body['token'] as String;
    final refreshToken = body['refreshToken'] as String?;
    final role = body['role'] as String? ?? fallbackRole;
    final isAdmin = body['isAdmin'] as bool? ?? false;
    final requiresPasswordChange =
        body['requiresPasswordChange'] as bool? ?? false;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveRole(role);
    await SecureStorage.saveIsAdmin(isAdmin);
    await SecureStorage.saveRequiresPasswordChange(requiresPasswordChange);
  }

  Future<String> registerAluno(
    String nome,
    String email,
    String password,
    String conviteToken, {
    String? personalSlug,
  }) async {
    final requestBody = <String, dynamic>{
      'nome': nome,
      'email': email,
      'senha': password,
      'conviteToken': conviteToken,
    };
    if (personalSlug != null) requestBody['personalSlug'] = personalSlug;
    final response = await _dio.post(
      '/api/auth/register/aluno',
      data: requestBody,
    );
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String?;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveRole('ALUNO');
    await SecureStorage.saveRequiresPasswordChange(false);
    return token;
  }

  Future<void> definirSenhaDefinitivaAluno(
    String senhaAtual,
    String novaSenha,
  ) async {
    await _dio.post(
      '/api/auth/aluno/definir-senha',
      data: {'senhaAtual': senhaAtual, 'novaSenha': novaSenha},
    );
    await SecureStorage.saveRequiresPasswordChange(false);
  }

  Future<PasswordResetRequestResult> solicitarResetSenha({
    required String email,
    required bool isAluno,
    String? personalSlug,
  }) async {
    final response = await _dio.post(
      '/api/auth/esqueci-senha',
      data: {
        'email': email,
        'tipo': isAluno ? 'ALUNO' : 'PERSONAL',
        if (personalSlug != null) 'personalSlug': personalSlug,
      },
    );
    return PasswordResetRequestResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<String> validarResetCodigo({
    required String email,
    required String codigo,
    required bool isAluno,
    String? personalSlug,
  }) async {
    final response = await _dio.post(
      '/api/auth/resetar-senha/validar-codigo',
      data: {
        'email': email,
        'codigo': codigo,
        'tipo': isAluno ? 'ALUNO' : 'PERSONAL',
        if (personalSlug != null && personalSlug.isNotEmpty)
          'personalSlug': personalSlug,
      },
    );
    return (response.data as Map<String, dynamic>)['resetNonce'] as String;
  }

  Future<void> confirmarResetSenha({
    String? resetNonce,
    required String novaSenha,
  }) async {
    await _dio.post(
      '/api/auth/resetar-senha',
      data: {
        if (resetNonce != null && resetNonce.isNotEmpty)
          'resetNonce': resetNonce,
        'novaSenha': novaSenha,
      },
    );
  }

  Future<void> logout() async {
    // Antes de revogar a sessão, enquanto o JWT ainda existe.
    await FcmService.desregistrarToken(_dio);

    final refresh = await SecureStorage.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _dio.post(
          '/api/auth/logout',
          data: {'refreshToken': refresh},
          options: Options(
            extra: {
              'fxNoInvalidate': true,
              'fxNoOfflineQueue': true,
            },
          ),
        );
      } catch (_) {
        // Best-effort revoke — limpeza local segue no SessionInvalidator.
      }
    }
  }
}
