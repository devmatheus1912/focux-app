import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';
import 'aluno360_operacao_tab.dart';

/// Evolução tab layout: inteligente + timeline (side-by-side on tablet) → weight.
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

  Widget _section(int step, Widget child) {
    return Aluno360OperacaoEntrance(
      enabled: animateEntrance,
      delay: Duration(milliseconds: step * 40),
      onPlayed: onEntrancePlayed,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inteligente = _section(0, evolucaoCard);
    final timeline = _section(1, timelineCard);
    final weight = _section(2, weightCard);

    return Semantics(
      container: true,
      label: 'Conteúdo da aba evolução',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tablet =
                constraints.maxWidth >= Aluno360Layout.operacaoTabletBreakpoint;

            if (tablet) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: inteligente),
                      const SizedBox(width: Aluno360Layout.sectionGap),
                      Expanded(child: timeline),
                    ],
                  ),
                  const SizedBox(height: Aluno360Layout.sectionGap),
                  weight,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                inteligente,
                const SizedBox(height: Aluno360Layout.sectionGap),
                timeline,
                const SizedBox(height: Aluno360Layout.sectionGap),
                weight,
              ],
            );
          },
        ),
      ),
    );
  }
}
