import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/fx_utils.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/aluno_media_utils.dart';

enum AlunoAvatarVariant { list, hero, strip }

class AlunoAvatar extends StatelessWidget {
  const AlunoAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.variant = AlunoAvatarVariant.list,
    this.fallbackColor,
  });

  static const double heroSize = 44;
  static const double listSize = 48;
  static const double stripSize = 40;

  final String name;
  final String? photoUrl;
  final AlunoAvatarVariant variant;
  final Color? fallbackColor;

  bool get _onHero => variant == AlunoAvatarVariant.hero;

  double get _size =>
      switch (variant) {
        AlunoAvatarVariant.hero => heroSize,
        AlunoAvatarVariant.strip => stripSize,
        AlunoAvatarVariant.list => listSize,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final resolvedUrl = resolveAlunoPhotoUrl(photoUrl);
    final ringColor =
        _onHero
            ? BrandPalette.accent(primary).withValues(
              alpha: isDark ? 0.96 : 0.88,
            )
            : BrandPalette.accent(primary).withValues(
              alpha: isDark ? 0.96 : 0.88,
            );
    final glowColor =
        _onHero
            ? ringColor.withValues(alpha: isDark ? 0.28 : 0.2)
            : ringColor.withValues(alpha: isDark ? 0.42 : 0.36);

    Widget avatar;
    if (resolvedUrl != null) {
      avatar = Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: _onHero ? 2 : 2),
          boxShadow: [
            if (_onHero)
              BoxShadow(
                color: glowColor,
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: glowColor,
                blurRadius: isDark ? 14 : 12,
                offset: Offset.zero,
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
    } else {
      avatar = _AlunoAvatarInitials(
        name: name,
        size: _size,
        onHero: _onHero,
        primary: primary,
        isDark: isDark,
        fallbackColor: fallbackColor,
      );
    }

    return Semantics(
      label:
          resolvedUrl != null
              ? 'Foto de $name'
              : 'Avatar de $name, ${fxInitials(name)}',
      child: avatar,
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
    final fallback =
        fallbackColor ??
        (onHero
            ? alunoAvatarHeroFallbackColor(name)
            : alunoAvatarFallbackColor(name, isDark));

    if (onHero) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fallback,
          border: Border.all(
            color: BrandPalette.sectionAccent(primary, dark: isDark).withValues(
              alpha: isDark ? 0.32 : 0.22,
            ),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.18 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          fxInitials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      );
    }

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
