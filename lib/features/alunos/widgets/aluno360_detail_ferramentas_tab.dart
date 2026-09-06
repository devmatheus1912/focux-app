import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import 'aluno360_ferramentas_modules_grid.dart';
import 'aluno360_ferramentas_tab.dart';

class Aluno360DetailFerramentasTab extends ConsumerWidget {
  const Aluno360DetailFerramentasTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.perfilCompletion,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final int perfilCompletion;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BF / massa: only `/360/ferramentas.composicaoResumo` — never Avaliacao.comparativo.
    final ferramentasAsync = ref.watch(aluno360FerramentasBundleProvider(alunoId));
    final aderenciaSemanal =
        ref.watch(alunoAderenciaSemanalProvider(alunoId)).valueOrNull;
    final composicao = ferramentasAsync.valueOrNull?.composicaoResumo;
    final bf =
        composicao?.percGordura != null
            ? composicao!.percGordura!.toStringAsFixed(1)
            : null;
    final massaMagra =
        composicao?.massaMuscular != null
            ? composicao!.massaMuscular!.toStringAsFixed(1)
            : null;

    return Aluno360FerramentasTab(
      aluno: aluno,
      alunoId: alunoId,
      primary: primary,
      bf: bf,
      massaMagra: massaMagra,
      measurementsLoading:
          ferramentasAsync.isLoading && !ferramentasAsync.hasValue,
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      modulesSection: Aluno360FerramentasModulesGrid(
        aluno: aluno,
        alunoId: alunoId,
        primary: primary,
        perfilCompletion: perfilCompletion,
        bf: bf,
        massaMagra: massaMagra,
        aderenciaSemanal: aderenciaSemanal,
      ),
    );
  }
}
