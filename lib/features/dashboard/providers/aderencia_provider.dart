import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alunos/providers/alunos_provider.dart';

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
}

/// Top 3 alunos com maior aderência (últimos 7 dias) para o dashboard.
///
/// Backend já expõe `/api/alunos/{id}/aderencia-semanal` retornando 7 pontos:
/// `[{data: 'YYYY-MM-DD', checkins: N}, ...]`
final aderenciaTop3Provider = FutureProvider<List<AderenciaAlunoResumo>>((
  ref,
) async {
  final repo = ref.read(alunoRepositoryProvider);
  final alunos = await ref.watch(alunosProvider.future);

  // Mantém apenas alunos ativos (quando disponível) e limita para evitar N+1 pesado.
  final candidatos =
      alunos
          .where((a) => a.status == 'ATIVO')
          .take(
            12,
          ) // trade-off: evita muitas chamadas em contas com muitos alunos
          .toList();

  final items = <AderenciaAlunoResumo>[];
  for (final a in candidatos) {
    try {
      final weekly = await repo.aderenciaSemanal(a.id);
      final spark = weekly
          .map((e) => (e['checkins'] as num?)?.toDouble() ?? 0.0)
          .toList(growable: false);
      final total = spark.fold<double>(0, (p, v) => p + v).round();
      final percent = ((total / 7.0) * 100).round().clamp(0, 100);
      items.add(
        AderenciaAlunoResumo(
          alunoId: a.id,
          nome: a.nome,
          objetivo: a.objetivo,
          sparkline: spark,
          totalCheckinsSemana: total,
          aderenciaPercent: percent,
        ),
      );
    } catch (_) {
      // Ignora aluno que falhou (rede/403/etc) sem quebrar o dashboard inteiro.
    }
  }

  items.sort((x, y) => y.aderenciaPercent.compareTo(x.aderenciaPercent));
  return items.take(3).toList(growable: false);
});
