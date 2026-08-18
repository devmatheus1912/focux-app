import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';

/// Whether the student has a prescription objective on file.
bool alunoObjectiveIsDefined(String? value) => (value ?? '').trim().isNotEmpty;

/// "juntos" / "juntas" / "juntos(as)" from profile gender when known.
String retomarTreinoJuntoTerm(String? genero) {
  final g = (genero ?? '').trim().toLowerCase();
  if (g.startsWith('fem')) return 'juntas';
  if (g.startsWith('masc')) return 'juntos';
  return 'juntos(as)';
}

/// Fixes IA/backend outreach copy that defaults to masculine "juntos".
String sanitizeOutreachGenderTerms(String message, {String? genero}) {
  final junto = retomarTreinoJuntoTerm(genero);
  var out = message;

  if (junto == 'juntas') {
    return out
        .replaceAll(
          RegExp(r'Quer retomar juntos\?', caseSensitive: false),
          'Quer retomar juntas?',
        )
        .replaceAll(
          RegExp(r'retomar juntos\?', caseSensitive: false),
          'retomar juntas?',
        )
        .replaceAll(
          RegExp(r'voltar juntos\?', caseSensitive: false),
          'voltar juntas?',
        );
  }

  if (junto == 'juntos') {
    return out
        .replaceAll(
          RegExp(r'Quer retomar juntas\?', caseSensitive: false),
          'Quer retomar juntos?',
        )
        .replaceAll(
          RegExp(r'retomar juntas\?', caseSensitive: false),
          'retomar juntos?',
        );
  }

  return out
      .replaceAll(
        RegExp(r'Quer retomar juntos\?', caseSensitive: false),
        'Quer retomar juntos(as)?',
      )
      .replaceAll(
        RegExp(r'retomar juntos\?', caseSensitive: false),
        'retomar juntos(as)?',
      );
}

/// Human-readable objective label for cards and hero.
String prettyAlunoObjective(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return 'Objetivo pendente';

  final normalized =
      raw
          .toLowerCase()
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  if (normalized.isEmpty) return 'Objetivo pendente';

  return switch (normalized) {
    'musculacao' || 'musculaçao' => 'Musculação',
    'emagrecimento' => 'Emagrecimento',
    'hipertrofia' => 'Hipertrofia',
    'condicionamento' => 'Condicionamento',
    'forca' => 'Força',
    _ => normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              part.length <= 2
                  ? part.toUpperCase()
                  : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' '),
  };
}

Color alunoAvatarFallbackColor(String name, bool isDark, {Color? primary}) {
  final base = primary ?? BrandPalette.defaultPrimary;
  final hsl = HSLColor.fromColor(base);
  final sat = (hsl.saturation * 0.92).clamp(0.52, 0.78);
  final lights =
      isDark
          ? const [0.44, 0.38, 0.50, 0.34]
          : const [0.34, 0.28, 0.38, 0.24];
  final hash =
      name.isEmpty ? 0 : name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return hsl
      .withSaturation(sat)
      .withLightness(lights[hash % lights.length])
      .toColor();
}

/// Vivid fallback on teal hero — harmonized tints that sit on the gradient.
Color alunoAvatarHeroFallbackColor(String name) {
  const palette = [
    EagleTokens.avatarMint,
    EagleTokens.avatarSky,
    EagleTokens.avatarPink,
    EagleTokens.avatarLavender,
    EagleTokens.avatarOrange,
  ];
  final hash =
      name.isEmpty ? 0 : name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return palette[hash % palette.length];
}
