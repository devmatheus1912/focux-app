import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../utils/treino_atribuicao_prazo.dart';

/// Badge soft de prazo — paridade Hub (`_TinyBadge` / chips densos).
class TreinoPrazoBadge extends StatelessWidget {
  const TreinoPrazoBadge({
    super.key,
    required this.dataFim,
    required this.isDark,
    this.today,
  });

  final DateTime? dataFim;
  final bool isDark;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final label = TreinoAtribuicaoPrazo.chipLabel(dataFim, today: today);
    if (label == null) return const SizedBox.shrink();
    final atrasado = TreinoAtribuicaoPrazo.isAtrasado(dataFim, today: today);
    final color = atrasado ? EagleTokens.warn : Theme.of(context).colorScheme.primary;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: BrandPalette.soft(color, dark: isDark),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.chip(color).copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
