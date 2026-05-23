import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../animations/fx_rive_assets.dart';

/// Autoplay Rive animation from bundled assets (offline-first).
class FxRivePlayer extends StatelessWidget {
  const FxRivePlayer({
    super.key,
    required this.asset,
    this.networkUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.artboard,
    this.animation,
    this.stateMachine,
    this.fallback,
  });

  final String asset;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? artboard;
  final String? animation;
  final String? stateMachine;
  final Widget? fallback;

  void _bindControllers(Artboard artboard) {
    if (stateMachine != null) {
      final controller = StateMachineController.fromArtboard(
        artboard,
        stateMachine!,
      );
      if (controller != null) {
        artboard.addController(controller);
      }
      return;
    }
    if (animation != null) {
      artboard.addController(SimpleAnimation(animation!, autoplay: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: RiveAnimation.asset(
        asset,
        fit: fit,
        artboard: artboard,
        animations: animation == null ? null : [animation!],
        onInit: _bindControllers,
        placeHolder: fallback ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Full-screen celebration confetti (Avinash_Narayanan — Rive community).
class FxRiveCelebration extends StatelessWidget {
  const FxRiveCelebration({super.key, this.fallback});

  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FxRivePlayer(
        asset: FxRiveAssets.confettiSuccess,
        fit: BoxFit.cover,
        fallback: fallback,
      ),
    );
  }
}

/// Sparkle overlay for earned gamification badges.
class FxRiveBadgeGlow extends StatelessWidget {
  const FxRiveBadgeGlow({super.key, required this.size, this.fallback});

  final double size;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return FxRivePlayer(
      asset: FxRiveAssets.starSparkle,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallback: fallback,
    );
  }
}

/// Heart pulse for recovery / wearable surfaces.
class FxRiveHeartPulse extends StatelessWidget {
  const FxRiveHeartPulse({super.key, this.size = 28, this.fallback});

  final double size;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return FxRivePlayer(
      asset: FxRiveAssets.heartPulse,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallback:
          fallback ??
          Icon(Icons.favorite_rounded, size: size * 0.7, color: Colors.redAccent),
    );
  }
}
