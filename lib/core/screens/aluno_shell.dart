import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../widgets/fx_dock.dart';

class AlunoShell extends StatelessWidget {
  const AlunoShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final compact = MediaQuery.sizeOf(context).width < 390;
    final dockClearance = bottomInset + (compact ? 82.0 : 92.0);

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? EagleTokens.backgroundDark : EagleTokens.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: dockClearance),
            child: navigationShell,
          ),
          Positioned(
            bottom: bottomInset + 18,
            left: 14,
            right: 14,
            child: FxDock(
              items: FxDockItems.aluno,
              currentIndex: navigationShell.currentIndex,
              isDark: isDark,
              onTap:
                  (i) => navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
