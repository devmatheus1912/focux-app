import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../widgets/cinematic_mesh_background.dart';
import '../widgets/fx_dock.dart';

/// Shell scaffold wrapping the 5 main personal-trainer tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final compact = MediaQuery.sizeOf(context).width < 390;
    final dockClearance = bottomInset + (compact ? 82.0 : 92.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: CinematicMeshBackground(
          showCenterGlow: false,
          showCornerGlow: true,
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
        ),
      ),
    );
  }
}
