import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/features/checkin/utils/treinos_hub_texts.dart';
import 'package:focux_app/features/checkin/utils/treinos_hub_view.dart';
import 'package:focux_app/features/dashboard/utils/aluno_ritmo_linha.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

/// Home e Histórico leem a mesma sessão do mesmo jeito (antes um dizia
/// "3 exercícios" e o outro "Registrado sem séries").
void main() {
  final s = SPt();

  Map<String, dynamic> sessao({
    int concluidos = 0,
    int? feitas,
    int? planejadas,
    bool parcial = false,
  }) => {
    'id': 7,
    'treinoId': 3,
    'treinoNome': 'B · Puxar',
    'status': 'CONCLUIDO',
    'iniciadoEm': '2026-11-03T18:00:00',
    'concluidoEm': '2026-11-03T18:40:00',
    'exerciciosCount': 3,
    'exerciciosConcluidos': concluidos,
    'seriesFeitas': feitas,
    'seriesPlanejadas': planejadas,
    'parcial': parcial,
  };

  test('os dois formatos da API leem os mesmos campos de lista', () {
    final json = sessao(concluidos: 3, feitas: 12, planejadas: 12);
    for (final e in [
      ExecucaoTreino.fromJson(json),
      ExecucaoTreino.fromHistoricoResumoJson(json),
    ]) {
      expect(e.exerciciosConcluidos, 3);
      expect(e.seriesFeitas, 12);
      expect(e.seriesPlanejadas, 12);
    }
    expect(
      ExecucaoTreino.fromHistoricoResumoJson(sessao(parcial: true)).parcial,
      isTrue,
    );
  });

  String detalhe(Map<String, dynamic> json) =>
      treinosRecenteDetalhe(s, treinoRecenteDe(ExecucaoTreino.fromJson(json))!);

  test('completa: exercícios e duração', () {
    expect(
      detalhe(sessao(concluidos: 3, feitas: 12, planejadas: 12)),
      '3 exercícios · 40 min',
    );
  });

  test('parcial: séries feitas de planejadas', () {
    expect(
      detalhe(sessao(feitas: 1, planejadas: 12, parcial: true)),
      startsWith('1 de 12 séries'),
    );
  });

  test('uma série sem exercício completo não vira "sem séries"', () {
    expect(detalhe(sessao(feitas: 1, planejadas: 2)), startsWith('1 série'));
  });

  test('sem nenhuma série e sem duração: registrado sem séries', () {
    final json = sessao(feitas: 0, planejadas: 12)
      ..['concluidoEm'] = '2026-11-03T18:01:00';
    expect(detalhe(json), s.treinosSemSeries);
  });

  test('sessão aberta horas não mostra duração', () {
    final json = sessao(concluidos: 2, feitas: 6, planejadas: 6)
      ..['concluidoEm'] = '2026-11-03T21:40:00';
    expect(detalhe(json), '2 exercícios');
  });

  test('exercício com elástico não é maior carga', () {
    expect(exercicioDeAjuda('Barra fixa com elástico (superband)'), isTrue);
    expect(exercicioDeAjuda('Barra fixa assistida'), isTrue);
    expect(exercicioDeAjuda('Agachamento livre'), isFalse);
  });
}
