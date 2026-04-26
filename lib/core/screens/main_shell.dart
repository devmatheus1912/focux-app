import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../widgets/fx_dock.dart';

/// Shell scaffold wrapping the 5 main personal-trainer tabs.
///
/// Renders [navigationShell] (the current branch content) inside a Stack
/// with [FxDock] floating at bottom: safeArea + 18px.
///
/// Each branch screen has its own Scaffold + scroll view. The dock is overlaid
/// on top so content must add ~90px bottom padding to avoid hiding behind it.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? EagleTokens.backgroundDark : EagleTokens.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          navigationShell,
          Positioned(
            bottom: bottomInset + 18,
            left: 14,
            right: 14,
            child: FxDock(
              currentIndex: navigationShell.currentIndex,
              isDark: isDark,
              onTap: (i) => navigationShell.goBranch(
                i,
                // Re-tapping active tab scrolls to top (initialLocation = true
                // resets the branch to its initial route).
                initialLocation: i == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
