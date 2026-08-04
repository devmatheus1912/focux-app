import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import 'dashboard_provider.dart';

class AderenciaAlunoResumo {
  final int alunoId;
  final String nome;
  final String? objetivo;
  final List<double> sparkline;
  final int totalCheckinsSemana;
  final int aderenciaPercent;

  const AderenciaAlunoResumo({
    required this.alunoId,
    required this.nome,
    required this.objetivo,
    required this.sparkline,
    required this.totalCheckinsSemana,
    required this.aderenciaPercent,
  });

  factory AderenciaAlunoResumo.fromHomeItem(DashboardAderenciaTopItem item) {
    return AderenciaAlunoResumo(
      alunoId: item.alunoId,
      nome: item.nome,
      objetivo: item.objetivo,
      sparkline: item.sparkline,
      totalCheckinsSemana: item.totalCheckinsSemana,
      aderenciaPercent: item.aderenciaPercent,
    );
  }
}

/// Top 3 aderência — preferencialmente do BFF `/api/dashboard/home` (sem N+1).
final aderenciaTop3Provider = FutureProvider<List<AderenciaAlunoResumo>>((
  ref,
) async {
  final home = await ref.watch(dashboardHomeProvider.future);
  return home.topAderencia
      .map(AderenciaAlunoResumo.fromHomeItem)
      .toList(growable: false);
});
