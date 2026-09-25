import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import 'aluno360_ferramentas_modules_grid.dart';
import 'aluno360_ferramentas_tab.dart';
import '../../../core/utils/pt_br_display.dart';

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
    // BF / massa / anamnese tile: only `/360/ferramentas` — never sidecars.
    final ferramentasAsync = ref.watch(aluno360FerramentasBundleProvider(alunoId));
    final aderenciaSemanal =
        ref.watch(alunoAderenciaSemanalProvider(alunoId)).value;
    final composicao = ferramentasAsync.value?.composicaoResumo;
    final bf =
        composicao?.percGordura != null
            ? formatBrDecimal(composicao!.percGordura!)
            : null;
    final massaMagra =
        composicao?.massaMuscular != null
            ? formatBrDecimal(composicao!.massaMuscular!)
            : null;
    final anamneseLoading =
        ferramentasAsync.isLoading && !ferramentasAsync.hasValue;
    // null resumo (or null status) ⇒ não iniciada — no GET /anamnese for the tile.
    final anamneseStatus =
        ferramentasAsync.hasValue
            ? ferramentasAsync.value?.anamneseResumo?.status
            : null;

    return Aluno360FerramentasTab(
      aluno: aluno,
      alunoId: alunoId,
      primary: primary,
      bf: bf,
      massaMagra: massaMagra,
      measurementsLoading: anamneseLoading,
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
        anamneseStatus: anamneseStatus,
        anamneseLoading: anamneseLoading,
      ),
    );
  }
}
