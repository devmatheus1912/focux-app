import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/tokens_strip.dart';

/// Subtle entrance motion for screen bodies — safe to wrap scroll views.
class FxPremiumEntrance extends StatelessWidget {
  const FxPremiumEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (TokensStrip.prefersReducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.018, curve: Curves.easeOutCubic, duration: 280.ms);
  }
}
