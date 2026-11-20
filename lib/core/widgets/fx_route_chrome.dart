import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_system_chrome.dart';
import 'fx_chao.dart';
import 'fx_chao_scope.dart';

import '../router/estado_da_rota.dart';
/// Routes that keep their own immersive / marketing background (sem FxChao).
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

/// Wraps pushed sub-routes with the solid floor (FxChao) + system chrome.
class FxRouteChrome extends StatelessWidget {
  const FxRouteChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (FxChaoScope.of(context)) return child;

    final path = uriDaRota(context).path;
    if (_fxRouteUsesImmersiveChrome(path)) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FocuxSystemChrome.forDark(isDark),
      child: FxChao(
        child: FxChaoScope(active: true, child: child),
      ),
    );
  }
}
