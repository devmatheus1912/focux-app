import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum BrandGlassTone {
  /// Auth / dark surfaces — teal glass on charcoal.
  dark,

  /// Dashboard light mode — airy cyan glass on paper.
  light,
}

/// Default Focux mark — official transparent logo asset.
class BrandGlassMark extends StatelessWidget {
  const BrandGlassMark({
    super.key,
    required this.size,
    this.logoUrl,
    this.glowColor,
    this.shimmerAlpha,
    this.tone = BrandGlassTone.dark,
    this.enableBackdropBlur = true,
    this.bare = true,
  });

  /// Official Focux logo (transparent PNG, no extra chrome).
  static const markAsset = 'assets/images/logo_official.png';

  final double size;
  final String? logoUrl;
  final Color? glowColor;
  final double? shimmerAlpha;
  final BrandGlassTone tone;
  final bool enableBackdropBlur;

  /// When true, renders only the logo asset — no glass tile behind it.
  final bool bare;

  bool get _onLightSurface => tone == BrandGlassTone.light;

  @override
  Widget build(BuildContext context) {
    if (bare) {
      return _buildBareMark(context);
    }

    final primary = glowColor ?? Theme.of(context).colorScheme.primary;
    final radius = size * 0.26;
    final shimmer = shimmerAlpha ?? 0.15;

    final gradient =
        _onLightSurface
            ? const RadialGradient(
              center: Alignment(-0.3, -0.45),
              radius: 1.0,
              colors: [Color(0xFFE4F7F7), Color(0xFFF4F7F8)],
              stops: [0.0, 1.0],
            )
            : const RadialGradient(
              center: Alignment(-0.3, -0.5),
              radius: 1.0,
              colors: [Color(0xFF0D2830), Color(0xFF080C10)],
              stops: [0.0, 1.0],
            );

    final borderColor =
        _onLightSurface
            ? primary.withValues(alpha: 0.22)
            : EagleTokens.glassBorder;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: _onLightSurface ? 0.16 : 0.28),
            blurRadius: size * 0.26,
            offset: Offset(0, size * 0.05),
          ),
          if (!_onLightSurface && enableBackdropBlur)
            BoxShadow(
              color: EagleTokens.brandAccent.withValues(alpha: shimmer * 0.15),
              blurRadius: size * 0.32,
              spreadRadius: -size * 0.03,
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (_onLightSurface ? primary : EagleTokens.brandAccent).withValues(
                    alpha: _onLightSurface ? 0.14 : 0.10,
                  ),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
          if (!_onLightSurface && enableBackdropBlur)
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: _buildMarkImage(),
          ),
        ],
      ),
    );
  }

  Widget _buildBareMark(BuildContext context) {
    final primary = glowColor ?? Theme.of(context).colorScheme.primary;
    final shimmer = (shimmerAlpha ?? 0.42).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (!_onLightSurface) ...[
            Container(
              width: size * 1.42,
              height: size * 1.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: 0.20 * shimmer),
                    EagleTokens.brandAccent.withValues(alpha: 0.10 * shimmer),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38, 1.0],
                ),
              ),
            ),
            Container(
              width: size * 1.02,
              height: size * 1.02,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.32 * shimmer),
                    blurRadius: size * 0.24,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: size * 0.18,
                    offset: Offset(0, size * 0.06),
                  ),
                ],
              ),
            ),
          ] else
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: EagleTokens.ink.withValues(alpha: 0.10),
                    blurRadius: size * 0.14,
                    offset: Offset(0, size * 0.05),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: size,
            height: size,
            child: _buildMarkImage(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkImage() {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Image.network(
        logoUrl!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _assetMark(),
      );
    }
    return _assetMark();
  }

  Widget _assetMark() {
    return Image.asset(
      markAsset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }
}
