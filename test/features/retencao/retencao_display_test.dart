import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/pagina.dart';
import 'package:focux_app/features/retencao/data/retencao_repository.dart';
import 'package:focux_app/features/retencao/utils/retencao_display.dart';

void main() {
  RetencaoAlunoScore score({
    required int id,
    required String risco,
    int atual = 40,
  }) {
    return RetencaoAlunoScore(
      alunoId: id,
      alunoNome: 'Aluno $id',
      scoreAtual: atual,
      delta: 0,
      riscoChurn: risco,
    );
  }

  test('ordena risco alto primeiro e lê envelope Pagina', () {
    final sorted = sortedRetencaoScores([
      score(id: 1, risco: 'BAIXO', atual: 90),
      score(id: 2, risco: 'ALTO', atual: 20),
      score(id: 3, risco: 'MEDIO', atual: 50),
    ]);
    expect(sorted.first.alunoId, 2);
    expect(retencaoRiskCounts(sorted).alto, 1);
    expect(firstAltoRetencao(sorted)?.alunoId, 2);

    final pagina = Pagina.fromJson({
      'content': [
        {
          'alunoId': 9,
          'alunoNome': 'Ana',
          'scoreAtual': 22,
          'delta': 4,
          'riscoChurn': 'ALTO',
        },
      ],
      'page': 0,
      'size': 100,
      'totalElements': 1,
      'hasNext': false,
    }, (raw) => RetencaoAlunoScore.fromJson(Map<String, dynamic>.from(raw as Map)));
    expect(pagina.content.single.alunoNome, 'Ana');
    expect(pagina.hasNext, isFalse);

    final repo = File(
      'lib/features/retencao/data/retencao_repository.dart',
    ).readAsStringSync();
    expect(repo, contains('Pagina.fromJson'));
    expect(repo, isNot(contains('as List<dynamic>')));
  });
}
