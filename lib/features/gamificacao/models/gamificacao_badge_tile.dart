import 'package:flutter/material.dart';

import '../data/gamificacao_repository.dart';

/// Tile de badge para a tela de gamificação (UI tipada, sem Map).
class GamificacaoBadgeTile {
  const GamificacaoBadgeTile({
    required this.tipo,
    required this.icon,
    required this.label,
    required this.cor,
    required this.earned,
  });

  final String tipo;
  final String icon;
  final String label;
  final Color cor;
  final bool earned;
}

List<GamificacaoBadgeTile> buildGamificacaoBadgeTiles(
  GamificacaoData data,
  Color brand,
  Color lockedColor,
) {
  final earnedTypes = data.badges.map((b) => b.tipo).toSet();
  final tiles = <GamificacaoBadgeTile>[];

  for (final badge in data.badges) {
    const catalog = _badgeCatalog;
    final meta = catalog[badge.tipo];
    tiles.add(
      GamificacaoBadgeTile(
        tipo: badge.tipo,
        icon: meta?.icon ?? '🏅',
        label: meta?.label ?? badge.descricao,
        cor: brand,
        earned: true,
      ),
    );
  }

  for (final entry in _badgeCatalog.entries) {
    if (earnedTypes.contains(entry.key)) continue;
    tiles.add(
      GamificacaoBadgeTile(
        tipo: entry.key,
        icon: entry.value.icon,
        label: entry.value.label,
        cor: lockedColor,
        earned: false,
      ),
    );
  }

  return tiles;
}

const _badgeCatalog = <String, ({String icon, String label})>{
  'STREAK_10': (icon: '🔥', label: 'Sequencia 10d'),
  'PR_CARGA': (icon: '💪', label: 'PR de carga'),
  'FREQUENCIA_100': (icon: '⭐', label: '100% semana'),
  'FIRST_AI': (icon: '✨', label: 'Usou a IA'),
  'TREINOS_50': (icon: '🏆', label: '50 treinos'),
  'META_ATINGIDA': (icon: '🎯', label: 'Meta atingida'),
};
