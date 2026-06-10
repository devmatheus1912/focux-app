import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';

/// Fade/slide entry for dashboard sections; skips motion when OS requests it.
Widget dashboardEntryMotion({
  required BuildContext context,
  required Animation<double> fade,
  required Widget child,
  Offset slideBegin = const Offset(0, 0.04),
}) {
  if (TokensStrip.prefersReducedMotion(context)) return child;
  return FadeTransition(
    opacity: fade,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: slideBegin,
        end: Offset.zero,
      ).animate(fade),
      child: child,
    ),
  );
}

Duration dashboardMotionDuration(
  BuildContext context, {
  Duration normal = const Duration(milliseconds: 220),
}) => TokensStrip.prefersReducedMotion(context) ? Duration.zero : normal;
