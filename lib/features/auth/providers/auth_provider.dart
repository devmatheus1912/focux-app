import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/session_invalidator.dart';
import '../../../core/state/fx_value_notifier.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Liga funil de analytics ao Dio. Só no boot do app — nunca no provider
/// (widget tests leem `apiClientProvider` e o POST pendente trava o isolate).
void bindAnalyticsFunnelPoster(ApiClient client) {
  AnalyticsService.instance.funnelPoster = (tipoEvento, alunoId) async {
    await client.dio.post(
      '/api/analytics/evento',
      data: {
        'alunoId': alunoId,
        'tipoEvento': tipoEvento,
        'canal': 'APP',
      },
    );
  };
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

enum AuthStatus { unknown, authenticated, unauthenticated }

enum UserRole { personal, aluno }

class AuthNotifier extends Notifier<AuthStatus> {
  late AuthRepository _repo;
  UserRole? _currentRole;
  bool _requiresPasswordChange = false;

  UserRole? get currentRole => _currentRole;
  bool get requiresPasswordChange => _requiresPasswordChange;

  @override
  AuthStatus build() {
    _repo = ref.read(authRepositoryProvider);
    SessionInvalidator.listenable.addListener(_handleSessionInvalidated);
    ref.onDispose(
      () => SessionInvalidator.listenable.removeListener(
        _handleSessionInvalidated,
      ),
    );
    Future.microtask(_checkToken);
    return AuthStatus.unknown;
  }

  void _handleSessionInvalidated() {
    if (!ref.mounted) return;
    _currentRole = null;
    _requiresPasswordChange = false;
    state = AuthStatus.unauthenticated;
  }

  Future<void> _checkToken() async {
    if (!ref.mounted) return;
    final token = await SecureStorage.getToken();
    if (token != null) {
      final roleStr = await SecureStorage.getRole();
      final requiresPasswordChange =
          await SecureStorage.getRequiresPasswordChange();
      if (!ref.mounted) return;
      _currentRole = roleStr == 'ALUNO' ? UserRole.aluno : UserRole.personal;
      _requiresPasswordChange = requiresPasswordChange;
      state = AuthStatus.authenticated;
    } else {
      if (!ref.mounted) return;
      state = AuthStatus.unauthenticated;
    }
  }

  Future<AuthLoginResult> login(String email, String password) async {
    final result = await _repo.loginPersonal(email, password);
    if (result.mfaRequired) return result;
    _currentRole = UserRole.personal;
    _requiresPasswordChange = false;
    state = AuthStatus.authenticated;
    return result;
  }

  Future<void> register(
    String nome,
    String email,
    String password, {
    String? referralCodigo,
    String? telefone,
    String? emailCodigo,
  }) async {
    await _repo.registerPersonal(
      nome,
      email,
      password,
      referralCodigo: referralCodigo,
      telefone: telefone,
      emailCodigo: emailCodigo,
    );
    _currentRole = UserRole.personal;
    _requiresPasswordChange = false;
    state = AuthStatus.authenticated;
  }

  Future<EnviarCodigoEmailResult> enviarCodigoEmail(String email) {
    return _repo.enviarCodigoEmail(email);
  }

  Future<void> loginAluno(
    String email,
    String password, {
    String? personalSlug,
  }) async {
    _requiresPasswordChange = await _repo.loginAluno(
      email,
      password,
      personalSlug: personalSlug,
    );
    _currentRole = UserRole.aluno;
    state = AuthStatus.authenticated;
  }

  Future<AuthLoginResult> loginGoogle({
    required String idToken,
    required bool isAluno,
    String? personalSlug,
  }) async {
    final result = await _repo.loginGoogle(
      idToken: idToken,
      isAluno: isAluno,
      personalSlug: personalSlug,
    );
    if (result.mfaRequired) return result;
    _currentRole = isAluno ? UserRole.aluno : UserRole.personal;
    _requiresPasswordChange = false;
    state = AuthStatus.authenticated;
    return result;
  }

  Future<AuthLoginResult> loginApple({
    required String identityToken,
    required bool isAluno,
    String? fullName,
    String? email,
    String? personalSlug,
  }) async {
    final result = await _repo.loginApple(
      identityToken: identityToken,
      isAluno: isAluno,
      fullName: fullName,
      email: email,
      personalSlug: personalSlug,
    );
    if (result.mfaRequired) return result;
    _currentRole = isAluno ? UserRole.aluno : UserRole.personal;
    _requiresPasswordChange = false;
    state = AuthStatus.authenticated;
    return result;
  }

  /// Completa o login após o código TOTP / recovery.
  Future<void> verifyMfa({
    required String mfaToken,
    required String code,
  }) async {
    final result = await _repo.verifyMfa(mfaToken: mfaToken, code: code);
    if (result.mfaRequired) {
      throw StateError('MFA_STILL_REQUIRED');
    }
    _currentRole = UserRole.personal;
    _requiresPasswordChange = false;
    state = AuthStatus.authenticated;
  }

  Future<MfaStatus> mfaStatus() => _repo.mfaStatus();

  Future<MfaSetupPayload> mfaSetup() => _repo.mfaSetup();

  Future<void> mfaConfirm(String code) => _repo.mfaConfirm(code);

  Future<void> mfaDisable({
    String? senha,
    String? emailOtp,
    required String code,
  }) {
    return _repo.mfaDisable(senha: senha, emailOtp: emailOtp, code: code);
  }

  Future<String> mfaDisableRequestEmailOtp() =>
      _repo.mfaDisableRequestEmailOtp();

  Future<void> registerAluno(
    String nome,
    String email,
    String password,
    String conviteToken, {
    String? personalSlug,
  }) async {
    await _repo.registerAluno(
      nome,
      email,
      password,
      conviteToken,
      personalSlug: personalSlug,
    );
    _currentRole = UserRole.aluno;
    _requiresPasswordChange = false;
    state = AuthStatus.authenticated;
  }

  Future<void> definirSenhaDefinitivaAluno(
    String senhaAtual,
    String novaSenha,
  ) async {
    await _repo.definirSenhaDefinitivaAluno(senhaAtual, novaSenha);
    _requiresPasswordChange = false;
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    await _repo.logout();
    ApiClient.resetIdempotencyScopes();
    await SessionInvalidator.invalidate(reason: 'logout manual');
    _currentRole = null;
    _requiresPasswordChange = false;
    state = AuthStatus.unauthenticated;
  }
}

/// MFA token do challenge de login — só em memória (nunca SecureStorage).
class MfaChallenge {
  const MfaChallenge({required this.mfaToken, this.returnTo});

  final String mfaToken;
  final String? returnTo;
}

final mfaChallengeProvider = fxValueProvider<MfaChallenge?>(null);

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider.notifier).currentRole;
});

final requiresPasswordChangeProvider = Provider<bool>((ref) {
  ref.watch(authProvider);
  return ref.read(authProvider.notifier).requiresPasswordChange;
});
