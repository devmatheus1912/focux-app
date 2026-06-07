import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';
import 'aluno360_evolucao_inteligente_card.dart';
import 'aluno360_evolucao_tab.dart';
import 'aluno360_timeline_card.dart';
import 'aluno360_weight_activity_card.dart';

class Aluno360DetailEvolucaoTab extends StatelessWidget {
  const Aluno360DetailEvolucaoTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.ink,
    required this.evolucaoAsync,
    required this.timeline360Async,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final AsyncValue<List<Timeline360Event>> timeline360Async;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context) {
    return Aluno360EvolucaoTab(
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      evolucaoCard: Aluno360EvolucaoInteligenteCard(
        alunoId: alunoId,
        alunoNome: aluno.nome,
        evolucaoAsync: evolucaoAsync,
        isDark: isDark,
      ),
      timelineCard: Aluno360TimelineCard(
        aluno: aluno,
        timelineApiAsync: timeline360Async,
        isDark: isDark,
      ),
      weightCard: Aluno360WeightActivityCard(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        ink: ink,
      ),
    );
  }
}
