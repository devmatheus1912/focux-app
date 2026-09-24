import 'package:go_router/go_router.dart';

import '../screens/main_shell.dart';
import '../../features/dashboard/screens/personal_dashboard_screen.dart';
import '../../features/alunos/screens/alunos_list_screen.dart';
import '../../features/treinos/screens/treinos_list_screen.dart';
import '../../features/agenda/screens/agenda_screen.dart';
import '../../features/ia/screens/ia_copiloto_screen.dart';
import 'app_router_redirect.dart';
import 'fx_lazy_shell_container.dart';

/// Personal trainer tab shell.
RouteBase buildPersonalShellRoute() {
  return StatefulShellRoute(
    navigatorContainerBuilder: fxLazyShellNavigatorContainer,
    builder:
        (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
    branches: [
      // Tab 0: Hoje (personal dashboard)
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/dashboard/personal',
            builder: (context, state) => const PersonalDashboardScreen(),
          ),
        ],
      ),
      // Tab 1: Alunos
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/alunos',
            builder:
                (context, state) => AlunosListScreen(
                  initialFiltro: alunoFiltroFromQuery(
                    state.uri.queryParameters['filtro'],
                  ),
                ),
          ),
        ],
      ),
      // Tab 2: Treinos
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/treinos',
            builder: (context, state) => const TreinosListScreen(),
          ),
        ],
      ),
      // Tab 3: Agenda
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/agenda',
            builder: (context, state) => const AgendaScreen(),
          ),
        ],
      ),
      // Tab 4: IA Copiloto
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/ia/copiloto',
            builder: (context, state) => const IaCopilotoScreen(),
          ),
        ],
      ),
    ],
  );
}
