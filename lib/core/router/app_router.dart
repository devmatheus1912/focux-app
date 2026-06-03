import 'package:go_router/go_router.dart';

import '../auth/session_invalidator.dart';
import 'app_router_auth_routes.dart';
import 'app_router_aluno_routes.dart';
import 'app_router_personal_shell_routes.dart';
import 'app_router_chrome_routes.dart';
import 'app_router_redirect.dart';
import 'qa_routes.dart' if (dart.vm.product) 'qa_routes_stub.dart';
import 'role_home.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const HomeRedirectScreen(),
    refreshListenable: SessionInvalidator.listenable,
    redirect: (context, state) async => authRedirect(state),
    routes: [
      ...buildAuthRoutes(),
      ...buildAlunoRoutes(),
      buildPersonalShellRoute(),
      buildChromeShellRoute(),
      ...buildQaRoutes(),
    ],
  );
}
