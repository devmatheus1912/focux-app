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

  Widget _section(int step, Widget child, {bool tablet = false}) {
    final baseMs = tablet ? 60 : 40;
    return Aluno360OperacaoEntrance(
      enabled: animateEntrance,
      delay: Duration(milliseconds: step * baseMs),
      onPlayed: onEntrancePlayed,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inteligente = _section(0, evolucaoCard);
    final timeline = _section(1, timelineCard);
    final weight = _section(2, weightCard);
    final inteligenteTablet = _section(0, evolucaoCard, tablet: true);
    final timelineTablet = _section(1, timelineCard, tablet: true);
    final weightTablet = _section(2, weightCard, tablet: true);

    return Semantics(
      container: true,
      label: 'Conteúdo da aba evolução',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tablet =
                constraints.maxWidth >= Aluno360Layout.operacaoTabletBreakpoint;

            if (tablet) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: inteligenteTablet),
                  const SizedBox(width: Aluno360Layout.sectionGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        timelineTablet,
                        const SizedBox(height: Aluno360Layout.sectionGap),
                        weightTablet,
                      ],
                    ),
                  ),
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
