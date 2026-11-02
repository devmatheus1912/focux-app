import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';
import 'aluno360_entrance.dart';

/// Evolução tab layout: inteligente, Corpo e linha do tempo.
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
    final weight = _section(1, weightCard);
    final timeline = _section(2, timelineCard);
    final inteligenteTablet = _section(0, evolucaoCard, tablet: true);
    final weightTablet = _section(1, weightCard, tablet: true);
    final timelineTablet = _section(2, timelineCard, tablet: true);

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
                        weightTablet,
                        const SizedBox(height: Aluno360Layout.sectionGap),
                        timelineTablet,
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
                weight,
                const SizedBox(height: Aluno360Layout.sectionGap),
                timeline,
              ],
            );
          },
        ),
      ),
    );
  }
}
