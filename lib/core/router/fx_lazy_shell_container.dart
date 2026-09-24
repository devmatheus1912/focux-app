import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../widgets/fx_lazy_indexed_stack.dart';

/// Container go_router: monta abas só na 1ª visita (mantém as já abertas).
Widget fxLazyShellNavigatorContainer(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  return FxLazyIndexedStack(
    index: navigationShell.currentIndex,
    children: children,
  );
}
