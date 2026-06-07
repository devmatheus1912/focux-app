import 'package:flutter/material.dart';

import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';

/// Legend for weekly adherence chart (check-in / miss / today).
class AlunoOperacaoAdherenceLegend extends StatelessWidget {
  const AlunoOperacaoAdherenceLegend({
    super.key,
    required this.activeColor,
    required this.missColor,
    required this.todayRingColor,
  });

  final Color activeColor;
  final Color missColor;
  final Color todayRingColor;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    return Semantics(
      label: 'Legenda: check-in, sem registro, hoje',
      child: ExcludeSemantics(
        child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _LegendItem(
            color: activeColor,
            label: 'Check-in',
            mute: mute,
          ),
          _LegendItem(
            color: missColor,
            label: 'Sem registro',
            mute: mute,
            solidMiss: true,
          ),
          _LegendItem(
            color: todayRingColor,
            label: 'Hoje',
            mute: mute,
            ring: true,
          ),
        ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.mute,
    this.solidMiss = false,
    this.ring = false,
  });

  final Color color;
  final String label;
  final Color mute;
  final bool solidMiss;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ring ? 12 : 8,
          height: ring ? 12 : 8,
          decoration: BoxDecoration(
            color:
                solidMiss
                    ? color.withValues(alpha: 0.92)
                    : ring
                    ? Colors.transparent
                    : color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border:
                ring
                    ? Border.all(color: color, width: 1.5)
                    : null,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Aluno360Layout.captionStyle(context).copyWith(
              color: mute,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
