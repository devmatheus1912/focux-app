import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand_palette.dart';

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

  static Color readableOn(Color background) => _readableOn(background);

  static bool isReadablePrimary(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    if (hsl.lightness > 0.86) return false;
    final onPrimary = _readableOn(primary);
    final contrast = _contrastRatio(primary, onPrimary);
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
    if (_contrastRatio(primary, secondary) < 1.35) return false;
    return true;
  }

  static Color safePrimary(Color color) {
    if (isReadablePrimary(color)) return color;
    return BrandPalette.defaultPrimary;
  }

  static Color safeSecondaryFor(Color primary, Color secondary) {
    final normalizedPrimary = safePrimary(primary);
    if (isSafePair(normalizedPrimary, secondary)) return secondary;
    return closest(normalizedPrimary, secondary).secondary;
  }

  static Color _readableOn(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF111318);
  }

  static double _contrastRatio(Color a, Color b) {
    final l1 = _relativeLuminance(a);
    final l2 = _relativeLuminance(b);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _relativeLuminance(Color color) {
    double channel(double value) {
      final v = value / 255;
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = channel(color.r * 255);
    final g = channel(color.g * 255);
    final b = channel(color.b * 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
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
