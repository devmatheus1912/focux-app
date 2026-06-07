import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';
import 'aluno360_operacao_tab.dart';

/// Evolução tab layout: inteligente card → timeline → weight activity.
class Aluno360EvolucaoTab extends StatelessWidget {
  const Aluno360EvolucaoTab({
    super.key,
    required this.evolucaoCard,
    required this.timelineCard,
    required this.weightCard,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Widget evolucaoCard;
  final Widget timelineCard;
  final Widget weightCard;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        evolucaoCard,
        const SizedBox(height: Aluno360Layout.sectionGap),
        Aluno360OperacaoEntrance(
          enabled: animateEntrance,
          delay: const Duration(milliseconds: 40),
          onPlayed: onEntrancePlayed,
          child: timelineCard,
        ),
        const SizedBox(height: Aluno360Layout.sectionGap),
        Aluno360OperacaoEntrance(
          enabled: animateEntrance,
          delay: const Duration(milliseconds: 80),
          onPlayed: onEntrancePlayed,
          child: weightCard,
        ),
      ],
    );
  }
}
