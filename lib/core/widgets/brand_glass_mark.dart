import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Default Focux mark: transparent F over in-app glass cyan tile.
/// Matches AuthShell / EagleTokens — no baked PNG background.
class BrandGlassMark extends StatelessWidget {
  const BrandGlassMark({
    super.key,
    required this.size,
    this.logoUrl,
    this.glowColor,
    this.shimmerAlpha,
  });

  static const markAsset = 'assets/images/logo_mark_transparent.png';

  final double size;
  final String? logoUrl;
  final Color? glowColor;
  final double? shimmerAlpha;

  @override
  Widget build(BuildContext context) {
    final primary = glowColor ?? Theme.of(context).colorScheme.primary;
    final radius = size * 0.26;
    final shimmer = shimmerAlpha ?? 0.15;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color(0xFF0D2830), Color(0xFF080C10)],
          stops: [0.0, 1.0],
        ),
        border: Border.all(color: EagleTokens.glassBorder),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: size * 0.26,
            offset: Offset(0, size * 0.05),
          ),
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
                  EagleTokens.brandAccent.withValues(alpha: 0.10),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.11),
            child: _buildMarkImage(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkImage() {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.14),
        child: Image.network(
          logoUrl!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _assetMark(),
        ),
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
