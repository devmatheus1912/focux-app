import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'cinematic_mesh_background.dart';
import 'mesh_scope.dart';

/// Routes that keep their own immersive / marketing background.
const _immersiveRoutePrefixes = [
  '/treino-presencial/',
  '/promo-enterprise',
];

bool _fxRouteUsesImmersiveChrome(String path) {
  for (final prefix in _immersiveRoutePrefixes) {
    if (path.startsWith(prefix)) return true;
  }
  return path == '/promo-enterprise';
}

/// Wraps pushed sub-routes with cinematic mesh + system chrome.
class FxRouteChrome extends StatelessWidget {
  const FxRouteChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MeshScope.of(context)) return child;

    final path = GoRouterState.of(context).uri.path;
    if (_fxRouteUsesImmersiveChrome(path)) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: CinematicMeshBackground(
        showCenterGlow: false,
        showCornerGlow: true,
        child: MeshScope(active: true, child: child),
      ),
    );
  }
}
