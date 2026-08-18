import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../platform/focux_platform.dart';
import '../theme/focux_system_chrome.dart';
import '../widgets/cinematic_mesh_background.dart';
import '../widgets/fx_dock.dart';
import '../widgets/mesh_scope.dart';

/// Shell scaffold wrapping the 5 main personal-trainer tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = FocuxPlatform.safeBottomInset(context);
    final compact = FocuxPlatform.isCompact(context);
    final dockClearance = bottomInset + (compact ? 102.0 : 112.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FocuxSystemChrome.forDark(isDark),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: MeshScope(
          active: true,
          child: CinematicMeshBackground(
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
      ),
    );
  }
}
