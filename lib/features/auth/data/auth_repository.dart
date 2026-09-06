import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/fcm/fcm_service.dart';
import '../../../core/storage/secure_storage.dart';

class PasswordResetRequestResult {
  final String mensagem;

  const PasswordResetRequestResult({required this.mensagem});

  factory PasswordResetRequestResult.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequestResult(
      mensagem:
          json['mensagem'] as String? ??
          'Se o e-mail estiver cadastrado, voce recebera as instrucoes.',
    );
  }
}

class AuthCapabilities {
  final bool passwordResetEmailAvailable;
  final bool appleSignInEnabled;
  final bool personalMfaTotpAvailable;

  const AuthCapabilities({
    required this.passwordResetEmailAvailable,
    required this.appleSignInEnabled,
    required this.personalMfaTotpAvailable,
  });

  factory AuthCapabilities.fromJson(Map<String, dynamic> json) {
    return AuthCapabilities(
      passwordResetEmailAvailable:
          json['passwordResetEmailAvailable'] as bool? ?? false,
      appleSignInEnabled: json['appleSignInEnabled'] as bool? ?? false,
      personalMfaTotpAvailable:
          json['personalMfaTotpAvailable'] as bool? ?? false,
    );
  }
}

/// Resultado de login e-mail/Google/Apple (Personal pode exigir MFA).
class AuthLoginResult {
  const AuthLoginResult._({required this.mfaRequired, this.mfaToken});

  const AuthLoginResult.authenticated()
    : this._(mfaRequired: false, mfaToken: null);

  const AuthLoginResult.mfaRequired(String token)
    : this._(mfaRequired: true, mfaToken: token);

  final bool mfaRequired;
  final String? mfaToken;
}

class MfaStatus {
  const MfaStatus({
    required this.enabled,
    required this.recoveryCodesRemaining,
  });

  final bool enabled;
  final int recoveryCodesRemaining;

  factory MfaStatus.fromJson(Map<String, dynamic> json) {
    return MfaStatus(
      enabled: json['enabled'] as bool? ?? false,
      recoveryCodesRemaining: json['recoveryCodesRemaining'] as int? ?? 0,
    );
  }
}

class MfaSetupPayload {
  const MfaSetupPayload({
    required this.secret,
    required this.otpauthUri,
    required this.recoveryCodes,
  });

  final String secret;
  final String otpauthUri;
  final List<String> recoveryCodes;

  factory MfaSetupPayload.fromJson(Map<String, dynamic> json) {
    final raw = json['recoveryCodes'];
    return MfaSetupPayload(
      secret: json['secret'] as String? ?? '',
      otpauthUri: json['otpauthUri'] as String? ?? '',
      recoveryCodes:
          raw is List
              ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
              : const [],
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
  final String title;
  final String detail;
  final String action;

  const AuthEnvironmentIssue({
    required this.area,
    required this.title,
    required this.detail,
    required this.action,
  });

  factory AuthEnvironmentIssue.fromJson(Map<String, dynamic> json) {
    return AuthEnvironmentIssue(
      area: json['area'] as String? ?? '',
      title: json['title'] as String? ?? 'Configuracao pendente',
      detail: json['detail'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }
}

class AuthEnvironmentStatus {
  final bool passwordResetReady;
  final bool googleSignInReady;
  final bool appleSignInReady;
  final bool appleSignInEnabled;
  final bool appleClientIdsConfigured;
  final List<AuthEnvironmentIssue> issues;
  final List<String> nextActions;

  const AuthEnvironmentStatus({
    required this.passwordResetReady,
    required this.googleSignInReady,
    required this.appleSignInReady,
    required this.appleSignInEnabled,
    required this.appleClientIdsConfigured,
    required this.issues,
    required this.nextActions,
  });

  factory AuthEnvironmentStatus.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'];
    final rawActions = json['nextActions'];
    return AuthEnvironmentStatus(
      passwordResetReady: json['passwordResetReady'] as bool? ?? false,
      googleSignInReady: json['googleSignInReady'] as bool? ?? false,
      appleSignInReady: json['appleSignInReady'] as bool? ?? false,
      appleSignInEnabled: json['appleSignInEnabled'] as bool? ?? false,
      appleClientIdsConfigured:
          json['appleClientIdsConfigured'] as bool? ?? false,
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

  /// Produção hoje: capabilities pode vir `false` enquanto environment-status
  /// já marca Apple pronto/ligado — o botão deve aparecer nesse caso.
  bool get appleSignInOffered =>
      appleSignInEnabled || appleSignInReady || appleClientIdsConfigured;

  AuthEnvironmentIssue? firstIssueFor(String area) {
    for (final issue in issues) {
      if (issue.area == area) return issue;
    }
    return null;
  }
}

/// Une capabilities + environment-status (podem divergir no backend).
bool resolveAppleSignInOffered({
  required bool capabilitiesEnabled,
  AuthEnvironmentStatus? environmentStatus,
}) {
  if (capabilitiesEnabled) return true;
  return environmentStatus?.appleSignInOffered ?? false;
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

  Future<AuthLoginResult> loginPersonal(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'senha': password},
    );
    return _consumeAuthResponse(
      response.data as Map<String, dynamic>,
      fallbackRole: 'PERSONAL',
    );
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

  Future<AuthLoginResult> loginGoogle({
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
    return _consumeAuthResponse(
      response.data as Map<String, dynamic>,
      fallbackRole: isAluno ? 'ALUNO' : 'PERSONAL',
    );
  }

  /// Sign in with Apple — `POST /api/auth/apple`.
  Future<AuthLoginResult> loginApple({
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
    return _consumeAuthResponse(
      response.data as Map<String, dynamic>,
      fallbackRole: isAluno ? 'ALUNO' : 'PERSONAL',
    );
  }

  /// Login intermediário MFA — `POST /api/auth/mfa/verify`.
  Future<AuthLoginResult> verifyMfa({
    required String mfaToken,
    required String code,
  }) async {
    final response = await _dio.post(
      '/api/auth/mfa/verify',
      data: {'mfaToken': mfaToken, 'code': code.trim()},
    );
    return _consumeAuthResponse(
      response.data as Map<String, dynamic>,
      fallbackRole: 'PERSONAL',
    );
  }

  Future<MfaStatus> mfaStatus() async {
    final response = await _dio.get('/api/auth/mfa/status');
    return MfaStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MfaSetupPayload> mfaSetup() async {
    final response = await _dio.post('/api/auth/mfa/setup');
    return MfaSetupPayload.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> mfaConfirm(String code) async {
    await _dio.post('/api/auth/mfa/confirm', data: {'code': code.trim()});
  }

  Future<void> mfaDisable({required String senha, required String code}) async {
    await _dio.post(
      '/api/auth/mfa/disable',
      data: {'senha': senha, 'code': code.trim()},
    );
  }

  /// Interpreta AuthResponse: MFA challenge (sem persistir) ou sessão completa.
  Future<AuthLoginResult> _consumeAuthResponse(
    Map<String, dynamic> body, {
    required String fallbackRole,
  }) async {
    final mfaRequired = body['mfaRequired'] as bool? ?? false;
    if (mfaRequired) {
      final mfaToken = (body['mfaToken'] as String?)?.trim();
      if (mfaToken == null || mfaToken.isEmpty) {
        throw StateError('MFA_TOKEN_MISSING');
      }
      // token/refreshToken vêm null — não persiste sessão.
      return AuthLoginResult.mfaRequired(mfaToken);
    }
    await _persistAuthResponse(body, fallbackRole: fallbackRole);
    return const AuthLoginResult.authenticated();
  }

  Future<void> _persistAuthResponse(
    Map<String, dynamic> body, {
    required String fallbackRole,
  }) async {
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('AUTH_TOKEN_MISSING');
    }
    final refreshToken = body['refreshToken'] as String?;
    final role = body['role'] as String? ?? fallbackRole;
    final requiresPasswordChange =
        body['requiresPasswordChange'] as bool? ?? false;
    await SecureStorage.saveToken(token);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveRole(role);
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
