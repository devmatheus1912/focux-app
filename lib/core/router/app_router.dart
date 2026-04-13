import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/personal_dashboard_screen.dart';
import '../../features/dashboard/screens/aluno_dashboard_screen.dart';
import '../../features/alunos/screens/alunos_list_screen.dart';
import '../../features/alunos/screens/add_aluno_screen.dart';
import '../../features/alunos/screens/aluno_detail_screen.dart';
import '../../features/perfil/data/perfil_repository.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/perfil/screens/editar_perfil_screen.dart';
import '../../features/convites/screens/convites_screen.dart';
import '../../features/assinatura/screens/assinatura_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard/personal',
        builder: (context, state) => const PersonalDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/aluno',
        builder: (context, state) => const AlunoDashboardScreen(),
      ),
      GoRoute(
        path: '/alunos',
        builder: (context, state) => const AlunosListScreen(),
      ),
      GoRoute(
        path: '/alunos/novo',
        builder: (context, state) => const AddAlunoScreen(),
      ),
      GoRoute(
        path: '/alunos/:id',
        builder: (context, state) => AlunoDetailScreen(
          alunoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const PerfilScreen(),
      ),
      GoRoute(
        path: '/perfil/editar',
        builder: (context, state) => EditarPerfilScreen(
          perfil: state.extra as PerfilPersonal,
        ),
      ),
      GoRoute(
        path: '/convites',
        builder: (context, state) => const ConvitesScreen(),
      ),
      GoRoute(
        path: '/planos',
        builder: (context, state) => const AssinaturaScreen(),
      ),
    ],
  );
}
