import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../animations/fx_rive_assets.dart';

/// Autoplay Rive animation from bundled assets (offline-first).
///
/// Sem motor nativo (`RiveNative.init` falhou ou testes), mostra [fallback].
class FxRivePlayer extends StatefulWidget {
  const FxRivePlayer({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  @override
  State<FxRivePlayer> createState() => _FxRivePlayerState();
}

class _FxRivePlayerState extends State<FxRivePlayer> {
  FileLoader? _loader;

  @override
  void initState() {
    super.initState();
    _loader = _createLoader();
  }

  @override
  void didUpdateWidget(FxRivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _loader?.dispose();
      _loader = _createLoader();
    }
  }

  FileLoader? _createLoader() {
    if (!RiveNative.isInitialized) return null;
    return FileLoader.fromAsset(widget.asset, riveFactory: Factory.rive);
  }

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = widget.fallback ?? const SizedBox.shrink();
    final loader = _loader;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: loader == null
          ? fallback
          : RiveWidgetBuilder(
              fileLoader: loader,
              builder: (context, state) => switch (state) {
                RiveLoaded(:final controller) => RiveWidget(
                  controller: controller,
                  fit: _riveFit(widget.fit),
                ),
                RiveLoading() || RiveFailed() => fallback,
              },
            ),
    );
  }
}

Fit _riveFit(BoxFit fit) => switch (fit) {
  BoxFit.fill => Fit.fill,
  BoxFit.cover => Fit.cover,
  BoxFit.fitWidth => Fit.fitWidth,
  BoxFit.fitHeight => Fit.fitHeight,
  BoxFit.none => Fit.none,
  BoxFit.scaleDown => Fit.scaleDown,
  BoxFit.contain => Fit.contain,
};

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
