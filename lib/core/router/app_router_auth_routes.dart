import 'package:go_router/go_router.dart';

import '../../features/auth/screens/definir_senha_aluno_screen.dart';
import '../../features/auth/screens/esqueci_senha_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_aluno_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/resetar_senha_verificar_codigo_screen.dart';
import '../../features/auth/screens/resetar_senha_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import 'role_home.dart';

/// Public and auth routes (no shell).
List<RouteBase> buildAuthRoutes() {
  return [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeRedirectScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const HomeRedirectScreen(),
    ),
    GoRoute(
      path: '/dashboard/home',
      builder: (context, state) => const HomeRedirectScreen(),
    ),
    GoRoute(path: '/aluno', redirect: (context, state) => '/dashboard/aluno'),
    GoRoute(
      path: '/personal',
      redirect: (context, state) => '/dashboard/personal',
    ),
    GoRoute(path: '/ia', redirect: (context, state) => '/ia/copiloto'),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(
        referralCodigo: state.uri.queryParameters['ref'],
      ),
    ),
    GoRoute(
      path: '/register/aluno',
      builder: (context, state) => RegisterAlunoScreen(
        personalSlug: state.uri.queryParameters['p'],
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/esqueci-senha',
      builder: (context, state) => const EsqueciSenhaScreen(),
    ),
    GoRoute(
      path: '/resetar-senha/verificar-codigo',
      builder: (context, state) => const ResetarSenhaVerificarCodigoScreen(),
    ),
    GoRoute(
      path: '/resetar-senha',
      builder: (context, state) => ResetarSenhaScreen(
        token: state.uri.queryParameters['token'],
        resetNonce: state.uri.queryParameters['resetNonce'],
      ),
    ),
    GoRoute(
      path: '/aluno/definir-senha',
      builder: (context, state) => const DefinirSenhaAlunoScreen(),
    ),
  ];
}
