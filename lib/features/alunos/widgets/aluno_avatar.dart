import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/fx_utils.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/aluno_media_utils.dart';

enum AlunoAvatarVariant { list, hero }

class AlunoAvatar extends StatelessWidget {
  const AlunoAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.variant = AlunoAvatarVariant.list,
    this.fallbackColor,
  });

  final String name;
  final String? photoUrl;
  final AlunoAvatarVariant variant;
  final Color? fallbackColor;

  bool get _onHero => variant == AlunoAvatarVariant.hero;

  double get _size =>
      switch (variant) {
        AlunoAvatarVariant.hero => 36,
        AlunoAvatarVariant.list => 46,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final resolvedUrl = resolveAlunoPhotoUrl(photoUrl);
    final ringColor =
        _onHero
            ? Colors.white.withValues(alpha: 0.88)
            : BrandPalette.accent(primary).withValues(
              alpha: isDark ? 0.96 : 0.88,
            );
    final glowColor =
        _onHero
            ? Colors.white.withValues(alpha: 0.22)
            : ringColor.withValues(alpha: isDark ? 0.42 : 0.36);

    if (resolvedUrl != null) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: _onHero ? 12 : (isDark ? 14 : 12),
              offset: Offset(0, _onHero ? 4 : 0),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Image.network(
            resolvedUrl,
            width: _size - 8,
            height: _size - 8,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder:
                (_, __, ___) => _AlunoAvatarInitials(
                  name: name,
                  size: _size - 4,
                  onHero: _onHero,
                  primary: primary,
                  isDark: isDark,
                  fallbackColor: fallbackColor,
                ),
          ),
        ),
      );
    }

    return _AlunoAvatarInitials(
      name: name,
      size: _onHero ? 36 : 44,
      onHero: _onHero,
      primary: primary,
      isDark: isDark,
      fallbackColor: fallbackColor,
    );
  }
}

class _AlunoAvatarInitials extends StatelessWidget {
  const _AlunoAvatarInitials({
    required this.name,
    required this.size,
    required this.onHero,
    required this.primary,
    required this.isDark,
    this.fallbackColor,
  });

  final String name;
  final double size;
  final bool onHero;
  final Color primary;
  final bool isDark;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (onHero) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          fxInitials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final fallback =
        fallbackColor ?? alunoAvatarFallbackColor(name, isDark);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallback,
        shape: BoxShape.circle,
        border: Border.all(
          color: BrandPalette.sectionAccent(primary, dark: isDark).withValues(
            alpha: isDark ? 0.28 : 0.18,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        fxInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
