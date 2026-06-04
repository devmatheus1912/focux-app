import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';

/// Human-readable objective label for cards and hero.
String prettyAlunoObjective(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return 'Objetivo não definido';

  final normalized =
      raw
          .toLowerCase()
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  if (normalized.isEmpty) return 'Objetivo não definido';

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

Color alunoAvatarFallbackColor(String name, bool isDark) {
  final palette =
      isDark
          ? const [
            Color(0xFF1EC8C8),
            Color(0xFF26A8A8),
            Color(0xFF159A9A),
            Color(0xFF32D4D4),
          ]
          : const [
            Color(0xFF1EC8C8),
            Color(0xFF26A8A8),
            Color(0xFF5EEAD4),
            Color(0xFF159A9A),
          ];
  final hash = name.isNotEmpty ? name.codeUnitAt(0) : 0;
  return palette[hash % palette.length];
}

Color alunoAvatarFallbackSoft(Color primary, String name, bool isDark) {
  return BrandPalette.soft(primary, dark: isDark);
}
