import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../exercicios/screens/exercicios_list_screen.dart';
import '../constants/treinos_layout.dart';

/// Aba Exercícios dentro de Treinos: o seletor Semanas | Exercícios e a lista
/// dos exercícios, que devolve o resumo do topo ("3 seus · 492 da biblioteca").
class ExerciciosAbaTreinos extends StatelessWidget {
  const ExerciciosAbaTreinos({
    super.key,
    required this.abas,
    required this.onResumoTopo,
  });

  final Widget abas;
  final ValueChanged<String?> onResumoTopo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TreinosLayout.screenPadding,
            TokensStrip.s2,
            TreinosLayout.screenPadding,
            TokensStrip.s2,
          ),
          child: abas,
        ),
        Expanded(
          child: ExerciciosListScreen(embedded: true, onResumoTopo: onResumoTopo),
        ),
      ],
    );
  }
}
