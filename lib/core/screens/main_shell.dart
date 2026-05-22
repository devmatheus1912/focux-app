import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../widgets/cinematic_mesh_background.dart';
import '../widgets/fx_dock.dart';

/// Shell scaffold wrapping the 5 main personal-trainer tabs.
///
/// Renders [navigationShell] (the current branch content) inside a Stack
/// with [FxDock] floating at bottom: safeArea + 18px.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final compact = MediaQuery.sizeOf(context).width < 390;
    final dockClearance = bottomInset + (compact ? 82.0 : 92.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: EagleTokens.darkBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: CinematicMeshBackground(
          showCenterGlow: false,
          showCornerGlow: false,
          child: Stack(
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
                  items: FxDockItems.personal,
                  currentIndex: navigationShell.currentIndex,
                  cinematicChrome: true,
                  isDark: true,
                  onTap:
                      (i) => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
