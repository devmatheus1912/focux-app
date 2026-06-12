import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../platform/focux_platform.dart';
import '../widgets/cinematic_mesh_background.dart';
import '../widgets/fx_dock.dart';
import '../widgets/mesh_scope.dart';

class AlunoShell extends StatelessWidget {
  const AlunoShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = FocuxPlatform.safeBottomInset(context);
    final compact = FocuxPlatform.isCompact(context);
    final dockClearance = bottomInset + (compact ? 88.0 : 98.0);

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
                    items: FxDockItems.aluno,
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
