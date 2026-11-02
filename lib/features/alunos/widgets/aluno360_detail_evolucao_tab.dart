import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';
import 'aluno360_evolucao_inteligente_card.dart';
import 'aluno360_evolucao_tab.dart';
import 'aluno360_timeline_card.dart';
import 'aluno360_weight_activity_card.dart';

bool _evolucaoSemDados(AsyncValue<EvolucaoInteligente> evolucaoAsync) {
  final ev = evolucaoAsync.value;
  if (ev == null) return evolucaoAsync.isLoading;
  return ev.sinal == 'SEM_DADOS';
}

bool _hasRadarP0(List<Timeline360Event> events) {
  return events.any(
    (e) =>
        e.tipo == 'RADAR' && e.prioridade.trim().toUpperCase().startsWith('P0'),
  );
}

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
    this.onOpenCopilot,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final AsyncValue<List<Timeline360Event>> timeline360Async;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;
  final VoidCallback? onOpenCopilot;

  @override
  Widget build(BuildContext context) {
    final timelineEvents = timeline360Async.value ?? const [];
    final timelineHasSignals = timelineEvents.isNotEmpty;
    final hasRadarP0 = _hasRadarP0(timelineEvents);
    final evolucaoEmpty = _evolucaoSemDados(evolucaoAsync);
    final timelineEmpty = timeline360Async.hasValue && timelineEvents.isEmpty;
    final bothEmpty =
        evolucaoEmpty &&
        timelineEmpty &&
        !evolucaoAsync.isLoading &&
        !timeline360Async.isLoading;

    return Aluno360EvolucaoTab(
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      evolucaoCard: Aluno360EvolucaoInteligenteCard(
        alunoId: alunoId,
        alunoNome: aluno.nome,
        evolucaoAsync: evolucaoAsync,
        isDark: isDark,
        onOpenCopilot: onOpenCopilot,
        timelineHasSignals: timelineHasSignals,
        hasRadarP0: hasRadarP0,
      ),
      timelineCard: Aluno360TimelineCard(
        aluno: aluno,
        timelineApiAsync: timeline360Async,
        isDark: isDark,
        compactEmpty: bothEmpty,
      ),
      weightCard: Aluno360WeightActivityCard(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        ink: ink,
        hasRadarP0: hasRadarP0,
        suppressRadarHint: timelineHasSignals,
      ),
    );
  }
}
