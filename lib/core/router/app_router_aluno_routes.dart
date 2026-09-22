import 'package:go_router/go_router.dart';

import '../screens/aluno_shell.dart';
import '../../features/dashboard/screens/aluno_dashboard_screen.dart';
import '../../features/dashboard/screens/aluno_activation_screen.dart';
import '../../features/dashboard/screens/perfil_aluno_screen.dart';
import '../../features/dashboard/screens/perfil_aluno_editar_screen.dart';
import '../../features/checkin/screens/meus_treinos_screen.dart';
import '../../features/health/screens/health_dashboard_screen.dart';
import '../../features/chat/screens/chat_aluno_screen.dart';
import '../../features/habitos/screens/habitos_aluno_screen.dart';
import '../../features/habitos/screens/habito_detail_screen.dart';
import '../../features/habitos/data/habito_repository.dart';
import '../../features/desafios/data/desafio_repository.dart';
import '../../features/desafios/screens/desafio_detail_screen.dart';
import '../../features/desafios/screens/desafios_aluno_screen.dart';
import 'app_router_redirect.dart';
import '../../features/recorrencia/screens/recorrencia_aluno_screen.dart';
import '../../features/grupos/screens/grupo_aulas_aluno_screen.dart';
import '../../features/anamnese/screens/anamnese_aluno_screen.dart';
import '../../features/trilhas/screens/aluno_trilhas_screen.dart';
import '../widgets/fx_route_chrome.dart';

/// Aluno shell and push routes.
List<RouteBase> buildAlunoRoutes() {
  return [
      // ── Aluno (student) dashboard — not part of personal trainer shell ────────
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                AlunoShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/aluno',
                builder: (context, state) => const AlunoDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/checkin/treinos',
                builder: (context, state) => const MeusTreinosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saude',
                builder: (context, state) => const HealthDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat/aluno',
                builder: (context, state) => const ChatAlunoScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/aluno/perfil',
                builder: (context, state) => const PerfilAlunoScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/aluno/ativacao',
        builder:
            (context, state) =>
                const FxRouteChrome(child: AlunoActivationScreen()),
      ),
      GoRoute(
        path: '/aluno/habitos',
        builder:
            (context, state) =>
                const FxRouteChrome(child: HabitosAlunoScreen()),
      ),
      GoRoute(
        path: '/aluno/habitos/:id',
        redirect:
            (context, state) =>
                intPathParam(state, 'id') == null ? '/aluno/habitos' : null,
        builder: (context, state) {
          final extra = state.extra;
          return FxRouteChrome(
            child: HabitoDetailScreen(
              habitoId: intPathParam(state, 'id')!,
              habito: extra is Habito ? extra : null,
              forAluno: true,
            ),
          );
        },
      ),
      GoRoute(
        path: '/aluno/desafios',
        builder:
            (context, state) =>
                const FxRouteChrome(child: DesafiosAlunoScreen()),
      ),
      GoRoute(
        path: '/aluno/desafios/:id',
        redirect:
            (context, state) =>
                intPathParam(state, 'id') == null ? '/aluno/desafios' : null,
        builder: (context, state) {
          final extra = state.extra;
          return FxRouteChrome(
            child: DesafioDetailScreen(
              desafioId: intPathParam(state, 'id')!,
              desafio: extra is Desafio ? extra : null,
              forAluno: true,
            ),
          );
        },
      ),
      GoRoute(
        path: '/aluno/recorrencia',
        builder: (context, state) => const FxRouteChrome(child: RecorrenciaAlunoScreen()),
      ),
      GoRoute(
        path: '/aluno/grupo-aulas',
        builder: (context, state) => const FxRouteChrome(child: GrupoAulasAlunoScreen()),
      ),
      // §38 hide: form-check fora do catálogo; deep link antigo → home aluno.
      GoRoute(
        path: '/aluno/form-check',
        redirect: (context, state) => '/dashboard/aluno',
      ),
      GoRoute(
        path: '/aluno/perfil/editar',
        builder:
            (context, state) =>
                const FxRouteChrome(child: PerfilAlunoEditarScreen()),
      ),
      GoRoute(
        path: '/aluno/anamnese',
        builder:
            (context, state) =>
                const FxRouteChrome(child: AnamneseAlunoScreen()),
      ),
      GoRoute(
        path: '/aluno/trilhas',
        builder:
            (context, state) =>
                const FxRouteChrome(child: AlunoTrilhasScreen()),
      ),
      GoRoute(
        path: '/evolucao',
        redirect: (context, state) => '/dashboard/aluno',
      ),
  ];
}
