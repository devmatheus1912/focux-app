import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/aluno_media_utils.dart';

enum AlunoAvatarVariant { list, hero, strip, profile }

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
  static const double profileSize = FxSettingsLayout.avatarSize;
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
    AlunoAvatarVariant.profile => profileSize,
  };

  bool get _perfilStyle => variant == AlunoAvatarVariant.profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final resolvedUrl = resolveAlunoPhotoUrl(photoUrl);
    final neon = BrandPalette.accent(primary);
    final ringPad = _perfilStyle ? FxSettingsLayout.avatarSize * 0.02 : _gap;
    final inner = _size - ringPad * 2;
    final fill =
        fallbackColor ??
        (_perfilStyle || variant == AlunoAvatarVariant.hero
            ? alunoAvatarHeroFallbackColor(name)
            : alunoAvatarFallbackColor(primary: primary));
    final initials = fxInitials(name);

    final face =
        resolvedUrl != null
            ? FxCachedNetworkImage(
              imageUrl: resolvedUrl,
              width: inner,
              height: inner,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder:
                  (_, __, ___) => _AlunoAvatarInitialsFace(
                    initials: initials,
                    fill: fill,
                    inner: inner,
                    perfilStyle: _perfilStyle,
                    primary: primary,
                  ),
            )
            : _AlunoAvatarInitialsFace(
              initials: initials,
              fill: fill,
              inner: inner,
              perfilStyle: _perfilStyle,
              primary: primary,
            );

    return Semantics(
      label:
          resolvedUrl != null
              ? 'Foto de $name'
              : 'Avatar de $name, $initials',
      child: Container(
        width: _size,
        height: _size,
        padding: EdgeInsets.all(ringPad),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _perfilStyle ? chrome.cardFill : null,
          border: Border.all(
            color:
                _perfilStyle
                    ? chrome.cardFill
                    : neon.withValues(alpha: isDark ? 0.96 : 0.82),
            width: _perfilStyle ? 0 : _ring,
          ),
          boxShadow:
              _perfilStyle
                  ? const [
                    BoxShadow(
                      color: EagleTokens.shadowSoft,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: neon.withValues(alpha: isDark ? 0.18 : 0.12),
                      blurRadius: isDark ? 10 : 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
        ),
        child: ClipOval(child: face),
      ),
    );
  }
}

class _AlunoAvatarInitialsFace extends StatelessWidget {
  const _AlunoAvatarInitialsFace({
    required this.initials,
    required this.fill,
    required this.inner,
    this.perfilStyle = false,
    this.primary,
  });

  final String initials;
  final Color fill;
  final double inner;
  final bool perfilStyle;
  final Color? primary;

  @override
  Widget build(BuildContext context) {
    final textColor = perfilStyle ? (primary ?? fill) : Colors.white;
    final textStyle =
        perfilStyle
            ? FxSettingsLayout.avatarInitials(color: textColor)
            : FocuxHubTypography.chip(Colors.white).copyWith(
              fontSize: (inner / 2) * 0.72,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1,
              color: Colors.white,
            );

    return ColoredBox(
      color: perfilStyle ? ShellChrome.of(context).cardFill : fill,
      child: Center(child: Text(initials, style: textStyle)),
    );
  }
}
