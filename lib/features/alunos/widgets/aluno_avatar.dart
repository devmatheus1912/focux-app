import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
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
  static const double _ring = 2;
  static const double _gap = 2;

  final String name;
  final String? photoUrl;
  final AlunoAvatarVariant variant;
  final Color? fallbackColor;

  double get _size => switch (variant) {
    AlunoAvatarVariant.hero => heroSize,
    AlunoAvatarVariant.strip => stripSize,
    AlunoAvatarVariant.list => listSize,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final resolvedUrl = resolveAlunoPhotoUrl(photoUrl);
    final neon = BrandPalette.accent(primary);
    final inner = _size - _gap * 2;
    final fill =
        fallbackColor ??
        (variant == AlunoAvatarVariant.hero
            ? alunoAvatarHeroFallbackColor(name)
            : alunoAvatarFallbackColor(primary: primary));
    final initials = fxInitials(name);

    return Semantics(
      label:
          resolvedUrl != null
              ? 'Foto de $name'
              : 'Avatar de $name, $initials',
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: neon.withValues(alpha: isDark ? 0.96 : 0.82),
            width: _ring,
          ),
          boxShadow: [
            BoxShadow(
              color: neon.withValues(alpha: isDark ? 0.18 : 0.12),
              blurRadius: isDark ? 10 : 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_gap),
        child: ClipOval(
          child:
              resolvedUrl != null
                  ? Image.network(
                    resolvedUrl,
                    width: inner,
                    height: inner,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder:
                        (_, __, ___) => _AlunoAvatarInitialsFace(
                          initials: initials,
                          fill: fill,
                          inner: inner,
                        ),
                  )
                  : _AlunoAvatarInitialsFace(
                    initials: initials,
                    fill: fill,
                    inner: inner,
                  ),
        ),
      ),
    );
  }
}

class _AlunoAvatarInitialsFace extends StatelessWidget {
  const _AlunoAvatarInitialsFace({
    required this.initials,
    required this.fill,
    required this.inner,
  });

  final String initials;
  final Color fill;
  final double inner;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: fill,
      child: Center(
        child: Text(
          initials,
          style: FocuxHubTypography.chip(Colors.white).copyWith(
            fontSize: (inner / 2) * 0.72,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
