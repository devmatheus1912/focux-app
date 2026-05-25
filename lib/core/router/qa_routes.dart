import 'package:go_router/go_router.dart';

import '../../features/qa/screens/qa_smoke_screen.dart';
import '../../features/qa/screens/tokens_strip_showcase_screen.dart';
import '../widgets/fx_route_chrome.dart';

/// Rotas de QA — importadas apenas em builds não-product (debug/profile).
List<RouteBase> buildQaRoutes() => [
  GoRoute(
    path: '/qa/smoke',
    builder: (context, state) => const FxRouteChrome(child: QaSmokeScreen()),
  ),
  GoRoute(
    path: '/qa/tokens-strip',
    builder:
        (context, state) =>
            const FxRouteChrome(child: TokensStripShowcaseScreen()),
  ),
];
