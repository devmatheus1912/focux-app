import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_system_chrome.dart';
import 'cinematic_mesh_background.dart';
import 'mesh_scope.dart';

import '../router/estado_da_rota.dart';
/// Routes that keep their own immersive / marketing background (no mesh wrap).
const _immersiveRoutePrefixes = [
  '/checkin/executar',
  '/promo-pro',
];

bool _fxRouteUsesImmersiveChrome(String path) {
  for (final prefix in _immersiveRoutePrefixes) {
    if (path == prefix || path.startsWith(prefix)) return true;
  }
  return false;
}

/// Wraps pushed sub-routes with cinematic mesh + system chrome.
class FxRouteChrome extends StatelessWidget {
  const FxRouteChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MeshScope.of(context)) return child;

    final path = uriDaRota(context).path;
    if (_fxRouteUsesImmersiveChrome(path)) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FocuxSystemChrome.forDark(isDark),
      child: CinematicMeshBackground(
        showCenterGlow: false,
        showCornerGlow: true,
        child: MeshScope(active: true, child: child),
      ),
    );
  }
}
