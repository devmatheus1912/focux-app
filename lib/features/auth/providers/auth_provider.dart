import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

enum AuthStatus { unknown, authenticated, unauthenticated }

enum UserRole { personal, aluno }

class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthRepository _repo;
  UserRole? _currentRole;

  UserRole? get currentRole => _currentRole;

  AuthNotifier(this._repo) : super(AuthStatus.unknown) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      final roleStr = await SecureStorage.getRole();
      _currentRole = roleStr == 'ALUNO' ? UserRole.aluno : UserRole.personal;
      state = AuthStatus.authenticated;
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String email, String password) async {
    await _repo.loginPersonal(email, password);
    _currentRole = UserRole.personal;
    state = AuthStatus.authenticated;
  }

  Future<void> register(String nome, String email, String password) async {
    await _repo.registerPersonal(nome, email, password);
    _currentRole = UserRole.personal;
    state = AuthStatus.authenticated;
  }

  Future<void> loginAluno(String email, String password) async {
    await _repo.loginAluno(email, password);
    _currentRole = UserRole.aluno;
    state = AuthStatus.authenticated;
  }

  Future<void> registerAluno(String nome, String email, String password, String conviteToken) async {
    await _repo.registerAluno(nome, email, password, conviteToken);
    _currentRole = UserRole.aluno;
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    await _repo.logout();
    _currentRole = null;
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider.notifier).currentRole;
});
