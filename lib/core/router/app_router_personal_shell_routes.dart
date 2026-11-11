import 'package:go_router/go_router.dart';

import '../screens/main_shell.dart';
import '../../features/dashboard/screens/personal_dashboard_screen.dart';
import '../../features/alunos/screens/alunos_list_screen.dart';
import '../../features/treinos/screens/modelos_de_treino_view.dart';
import '../../features/agenda/screens/agenda_screen.dart';
import '../../features/chat/screens/chat_inbox_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../observability/sentry_performance.dart';
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
        observers: sentryNavObservers(),
        routes: [
          GoRoute(
            path: '/dashboard/personal',
            builder: (context, state) => const PersonalDashboardScreen(),
          ),
        ],
      ),
      // Tab 1: Alunos
      StatefulShellBranch(
        observers: sentryNavObservers(),
        routes: [
          GoRoute(
            path: '/alunos',
            builder:
                (context, state) => AlunosListScreen(
                  initialFiltro: alunoFiltroFromQuery(
                    state.uri.queryParameters['filtro'],
                  ),
                  initialQuery: alunoBuscaFromQuery(
                    state.uri.queryParameters['q'],
                  ),
                ),
          ),
        ],
      ),
      // Tab 2: Conversas
      StatefulShellBranch(
        observers: sentryNavObservers(),
        routes: [
          GoRoute(
            path: '/chat/inbox',
            builder: (context, state) => const ChatInboxScreen(),
          ),
          // Conversa aberta pela aba: fica no ramo, com a barra de abas.
          GoRoute(
            path: '/chat/inbox/conversa/:id',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/chat/inbox' : null,
            builder:
                (context, state) => ChatScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: chatAlunoNomeExtra(state) ?? 'Aluno',
                  initialDraft: chatDraftExtra(state),
                ),
          ),
        ],
      ),
      // Tab 3: Agenda
      StatefulShellBranch(
        observers: sentryNavObservers(),
        routes: [
          GoRoute(
            path: '/agenda',
            builder: (context, state) => const AgendaScreen(),
          ),
        ],
      ),
      // Tab 4: Treinos
      StatefulShellBranch(
        observers: sentryNavObservers(),
        routes: [
          GoRoute(
            path: '/treinos',
            builder: (context, state) => ModelosDeTreinoView(
              abrirNovoModelo: state.uri.queryParameters['novo'] == '1',
            ),
          ),
        ],
      ),
    ],
  );
}
