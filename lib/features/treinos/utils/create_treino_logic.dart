import 'package:flutter/material.dart';

/// Preset de objetivo para criação de treino — SSOT fora da UI.
class TreinoCreatePreset {
  const TreinoCreatePreset({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

abstract final class CreateTreinoLogic {
  CreateTreinoLogic._();

  static const niveis = ['INICIANTE', 'INTERMEDIARIO', 'AVANCADO'];
  static const niveisLabel = ['Iniciante', 'Intermediário', 'Avançado'];
  static const niveisIcon = [
    Icons.eco_rounded,
    Icons.speed_rounded,
    Icons.local_fire_department_rounded,
  ];

  static const presets = [
    TreinoCreatePreset(
      title: 'Hipertrofia',
      subtitle: 'Volume e carga',
      icon: Icons.trending_up_rounded,
    ),
    TreinoCreatePreset(
      title: 'Emagrecimento',
      subtitle: 'Ritmo e aderência',
      icon: Icons.bolt_rounded,
    ),
    TreinoCreatePreset(
      title: 'Força',
      subtitle: 'Base e progressão',
      icon: Icons.fitness_center_rounded,
    ),
    TreinoCreatePreset(
      title: 'Condicionamento',
      subtitle: 'Capacidade geral',
      icon: Icons.speed_rounded,
    ),
  ];

  static String nivelLabel(String? code) {
    if (code == null) return 'Em aberto';
    final index = niveis.indexOf(code);
    if (index < 0) return 'Em aberto';
    return niveisLabel[index];
  }

  static String? matchingPresetTitle(String objetivoText) {
    final trimmed = objetivoText.trim();
    if (trimmed.isEmpty) return null;
    for (final preset in presets) {
      if (preset.title == trimmed) return preset.title;
    }
    return null;
  }

  static String planoBaseCaption({required bool hasNome}) {
    if (!hasNome) {
      return 'Comece pelo nome. Exercícios entram no passo seguinte.';
    }
    return 'Revise os dados e toque em Criar para montar os exercícios.';
  }

  static String previewMeta({
    required String objetivo,
    required String? nivel,
  }) {
    final parts = <String>[];
    final trimmedObjetivo = objetivo.trim();
    if (trimmedObjetivo.isNotEmpty) {
      parts.add(trimmedObjetivo);
    }
    parts.add(nivelLabel(nivel));
    return parts.join(' · ');
  }
}
