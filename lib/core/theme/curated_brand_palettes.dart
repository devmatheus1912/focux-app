import 'package:flutter/material.dart';

import 'brand_palette.dart';
import 'design_tokens.dart';
import 'focux_contrast.dart';

/// Curated primary + secondary pairs — always safe together in the app.
class CuratedBrandPalette {
  const CuratedBrandPalette({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.secondary,
  });

  final String id;
  final String name;
  final String subtitle;
  final Color primary;
  final Color secondary;

  static const focuxDefault = CuratedBrandPalette(
    id: 'focux_default',
    name: 'Focux Original',
    subtitle: 'Cyan oficial da plataforma',
    primary: BrandPalette.defaultPrimary,
    secondary: BrandPalette.defaultSecondary,
  );

  static const List<CuratedBrandPalette> premium = [
    focuxDefault,
    CuratedBrandPalette(
      id: 'midnight_gold',
      name: 'Midnight Gold',
      subtitle: 'Navy profundo com acento dourado',
      primary: Color(0xFF1A2332),
      secondary: Color(0xFFC9A962),
    ),
    CuratedBrandPalette(
      id: 'graphite_copper',
      name: 'Graphite Copper',
      subtitle: 'Grafite escuro e cobre sofisticado',
      primary: Color(0xFF2C3338),
      secondary: Color(0xFFB87333),
    ),
    CuratedBrandPalette(
      id: 'deep_navy_pearl',
      name: 'Deep Navy Pearl',
      subtitle: 'Azul noturno com perola clara',
      primary: Color(0xFF0F2744),
      secondary: Color(0xFF7EB8DA),
    ),
    CuratedBrandPalette(
      id: 'forest_sage',
      name: 'Forest Sage',
      subtitle: 'Verde profundo e menta premium',
      primary: Color(0xFF1B4332),
      secondary: Color(0xFF52B788),
    ),
    CuratedBrandPalette(
      id: 'charcoal_platinum',
      name: 'Charcoal Platinum',
      subtitle: 'Carvao elegante com prata fria',
      primary: Color(0xFF1E1E24),
      secondary: Color(0xFF9CA3AF),
    ),
    CuratedBrandPalette(
      id: 'royal_indigo',
      name: 'Royal Indigo',
      subtitle: 'Indigo intenso com lavanda',
      primary: Color(0xFF312E81),
      secondary: Color(0xFF818CF8),
    ),
    CuratedBrandPalette(
      id: 'obsidian_amber',
      name: 'Obsidian Amber',
      subtitle: 'Preto quente com ambar refinado',
      primary: Color(0xFF171717),
      secondary: Color(0xFFD97706),
    ),
    CuratedBrandPalette(
      id: 'slate_teal',
      name: 'Slate Teal',
      subtitle: 'Teal escuro com menta luminosa',
      primary: Color(0xFF134E4A),
      secondary: Color(0xFF5EEAD4),
    ),
    CuratedBrandPalette(
      id: 'burgundy_rose',
      name: 'Burgundy Rose',
      subtitle: 'Vinho profundo com rose suave',
      primary: Color(0xFF4A1942),
      secondary: Color(0xFFC08497),
    ),
  ];

  static CuratedBrandPalette? match(Color primary, Color secondary) {
    for (final palette in premium) {
      if (_sameColor(palette.primary, primary) &&
          _sameColor(palette.secondary, secondary)) {
        return palette;
      }
    }
    return null;
  }

  static CuratedBrandPalette resolve(Color primary, Color secondary) {
    return match(primary, secondary) ?? closest(primary, secondary);
  }

  static CuratedBrandPalette closest(Color primary, Color secondary) {
    var best = premium.first;
    var bestScore = double.infinity;
    for (final palette in premium) {
      final score =
          _colorDistance(palette.primary, primary) +
          _colorDistance(palette.secondary, secondary);
      if (score < bestScore) {
        bestScore = score;
        best = palette;
      }
    }
    return best;
  }

  static Color readableOn(Color background) =>
      FocuxContrast.readableOn(background);

  /// Acento de chrome (ícones, CTA, login). Paletas premium gravam o
  /// *clima* escuro em [primary] (navy, carvão) e o ouro/menta em
  /// [secondary]. No escuro, [primary] some no mesh — promovemos o
  /// papel visível sem regravar o hex no servidor.
  Color chromeFor({required bool dark}) =>
      chromeAccent(primary, secondary, dark: dark);

  static Color chromeAccent(
    Color primary,
    Color secondary, {
    required bool dark,
  }) {
    final surface = dark ? EagleTokens.darkBg : EagleTokens.paper;
    const minVsSurface = FocuxContrast.wcagAaLarge;
    if (FocuxContrast.contrastRatio(primary, surface) >= minVsSurface) {
      return primary;
    }
    if (!dark) {
      return primary;
    }
    var candidate = secondary;
    if (FocuxContrast.contrastRatio(candidate, surface) < minVsSurface) {
      candidate = BrandPalette.accent(primary);
    }
    return _ensureWhiteLabelOnDark(candidate, surface, minVsSurface);
  }

  /// Login e [FxLiquidPrimaryButton] pintam o rótulo de branco. Depois de
  /// promover um ouro/menta claro, escurece até o branco ler em AA (4.5:1)
  /// — sem voltar ao navy que some no mesh. 3:1 deixava o acento falhar
  /// [isReadablePrimary] e o [safeSecondaryFor] trocava o ouro pelo teal.
  static Color _ensureWhiteLabelOnDark(
    Color color,
    Color surface,
    double minVsSurface,
  ) {
    const white = Color(0xFFFFFFFF);
    const minWhite = FocuxContrast.wcagAaNormal;
    var hsl = HSLColor.fromColor(color);
    var current = color;
    for (var i = 0; i < 24; i++) {
      final vsWhite = FocuxContrast.contrastRatio(white, current);
      final vsSurface = FocuxContrast.contrastRatio(current, surface);
      if (vsWhite >= minWhite && vsSurface >= minVsSurface) {
        return current;
      }
      if (vsWhite < minWhite) {
        hsl = hsl.withLightness((hsl.lightness - 0.03).clamp(0.18, 0.72));
      } else {
        hsl = hsl.withLightness((hsl.lightness + 0.03).clamp(0.18, 0.72));
      }
      current = hsl.toColor();
    }
    return current;
  }

  /// Acento já levantado p/ mesh escuro (AuthShell / sheet forceDark).
  /// Não é [isReadablePrimary] de paleta *salva* — navy/carvão falham aqui
  /// de propósito; ouro/menta escurecido passa.
  static bool _isUsableDarkChrome(Color color) {
    final vsSurface = FocuxContrast.contrastRatio(color, EagleTokens.darkBg);
    final vsWhite = FocuxContrast.contrastRatio(const Color(0xFFFFFFFF), color);
    return vsSurface >= FocuxContrast.wcagAaLarge &&
        vsWhite >= FocuxContrast.wcagAaNormal;
  }

  static bool isReadablePrimary(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    if (hsl.lightness > 0.86) return false;
    final onPrimary = FocuxContrast.readableOn(primary);
    final contrast = FocuxContrast.contrastRatio(primary, onPrimary);
    if (contrast < 4.5) return false;
    // Dark neutrals (charcoal/obsidian) are valid brand primaries.
    if (hsl.lightness <= 0.18) return true;
    return hsl.saturation >= 0.12;
  }

  static bool isSafePair(Color primary, Color secondary) {
    if (!isReadablePrimary(primary)) return false;
    if (_sameColor(primary, secondary)) return false;

    final primaryHsl = HSLColor.fromColor(primary);
    final secondaryHsl = HSLColor.fromColor(secondary);
    final hueDelta = _hueDistance(primaryHsl.hue, secondaryHsl.hue);
    final lightnessDelta =
        (primaryHsl.lightness - secondaryHsl.lightness).abs();

    if (hueDelta < 18 && lightnessDelta < 0.12) return false;
    if (FocuxContrast.contrastRatio(primary, secondary) < 1.35) return false;
    return true;
  }

  static Color safePrimary(Color color) {
    if (isReadablePrimary(color)) return color;
    return BrandPalette.defaultPrimary;
  }

  static Color safeSecondaryFor(Color primary, Color secondary) {
    // AuthShell / forceDark reaplicam colorScheme.primary já remapado.
    // safePrimary disso virava teal Focux e closest() trocava o ouro.
    if (_isUsableDarkChrome(primary)) return secondary;
    final normalizedPrimary = safePrimary(primary);
    if (isSafePair(normalizedPrimary, secondary)) return secondary;
    return closest(normalizedPrimary, secondary).secondary;
  }

  static double _hueDistance(double a, double b) {
    final delta = (a - b).abs();
    return delta > 180 ? 360 - delta : delta;
  }

  static double _colorDistance(Color a, Color b) {
    final ar = a.r, ag = a.g, ab = a.b;
    final br = b.r, bg = b.g, bb = b.b;
    return ((ar - br) * (ar - br) +
            (ag - bg) * (ag - bg) +
            (ab - bb) * (ab - bb)) *
        255 *
        255;
  }

  static bool _sameColor(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}
