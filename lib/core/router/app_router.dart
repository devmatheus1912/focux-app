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
import '../../features/checkin/screens/meus_treinos_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../features/checkin/screens/historico_screen.dart';
import '../../features/exercicios/screens/exercicios_list_screen.dart';
import '../../features/exercicios/screens/exercicio_detail_screen.dart';
import '../../features/exercicios/screens/add_exercicio_screen.dart';
import '../../features/treinos/screens/treinos_list_screen.dart';
import '../../features/treinos/screens/treino_detail_screen.dart';
import '../../features/treinos/screens/create_treino_screen.dart';
import '../../features/treinos/screens/add_exercicio_to_treino_screen.dart';
import '../../features/financeiro/screens/financeiro_screen.dart';
import '../../features/agenda/screens/agenda_screen.dart';
import '../../features/relatorio/screens/relatorio_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/feed_aluno_screen.dart';

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
      GoRoute(
        path: '/exercicios',
        builder: (context, state) => const ExerciciosListScreen(),
      ),
      GoRoute(
        path: '/exercicios/novo',
        builder: (context, state) => const AddExercicioScreen(),
      ),
      GoRoute(
        path: '/exercicios/:id',
        builder: (context, state) => ExercicioDetailScreen(
          exercicioId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/treinos',
        builder: (context, state) => const TreinosListScreen(),
      ),
      GoRoute(
        path: '/treinos/novo',
        builder: (context, state) => const CreateTreinoScreen(),
      ),
      GoRoute(
        path: '/treinos/:id',
        builder: (context, state) => TreinoDetailScreen(
          treinoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/treinos/:id/exercicios/add',
        builder: (context, state) => AddExercicioToTreinoScreen(
          treinoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/checkin/treinos',
        builder: (context, state) => const MeusTreinosScreen(),
      ),
      GoRoute(
        path: '/checkin/executar',
        builder: (context, state) => CheckinScreen(treinoId: state.extra as int),
      ),
      GoRoute(
        path: '/checkin/historico',
        builder: (context, state) => const HistoricoCheckinScreen(),
      ),
      GoRoute(
        path: '/financeiro',
        builder: (context, state) => const FinanceiroScreen(),
      ),
      GoRoute(
        path: '/agenda',
        builder: (context, state) => const AgendaScreen(),
      ),
      GoRoute(
        path: '/alunos/:id/relatorio',
        builder: (context, state) => RelatorioScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/feed/aluno',
        builder: (context, state) => const FeedAlunoScreen(),
      ),
    ],
  );
}
