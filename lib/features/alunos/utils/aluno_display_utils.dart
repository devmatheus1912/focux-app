import 'package:flutter/material.dart';

/// Whether the student has a prescription objective on file.
bool alunoObjectiveIsDefined(String? value) => (value ?? '').trim().isNotEmpty;

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

/// Vivid fallback on teal hero — harmonized tints that sit on the gradient.
Color alunoAvatarHeroFallbackColor(String name) {
  const palette = [
    Color(0xFF5EEAD4),
    Color(0xFF7DD3FC),
    Color(0xFFF9A8D4),
    Color(0xFFC4B5FD),
    Color(0xFFFDBA74),
  ];
  final hash =
      name.isEmpty
          ? 0
          : name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return palette[hash % palette.length];
}
