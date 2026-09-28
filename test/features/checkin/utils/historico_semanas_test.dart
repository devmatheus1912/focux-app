import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/historico_semanas.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

/// Domingo, 27 de setembro de 2026, 18h: a semana atual começou na segunda, 21.
final _now = DateTime(2026, 9, 27, 18);
final _s = SPt();

var _id = 0;
ExecucaoTreino _sessao(
  DateTime concluido, {
  String status = 'CONCLUIDO',
  String nome = 'Treino A',
}) => ExecucaoTreino.fromHistoricoResumoJson({
  'id': ++_id,
  'treinoId': 1,
  'treinoNome': nome,
  'status': status,
  'iniciadoEm':
      concluido.subtract(const Duration(minutes: 50)).toIso8601String(),
  'concluidoEm': concluido.toIso8601String(),
  'exerciciosConcluidos': 4,
});

void main() {
  setUpAll(() => GlobalMaterialLocalizations.delegate.load(const Locale('pt')));

  test('agrupa por semana ISO, mais recente primeiro', () {
    final semanas = agruparHistoricoPorSemana(
      [
        _sessao(DateTime(2026, 9, 21, 7)),
        _sessao(DateTime(2026, 9, 27, 9)),
        _sessao(DateTime(2026, 9, 20, 22)),
        _sessao(DateTime(2026, 9, 2, 12)),
      ],
      now: _now,
      temMais: false,
    );

    expect(semanas.map((w) => w.tipo), [
      HistoricoSemanaTipo.atual,
      HistoricoSemanaTipo.passada,
      HistoricoSemanaTipo.anterior,
    ]);
    expect(semanas.first.inicio, DateTime(2026, 9, 21));
    expect(semanas.first.sessoes.map((r) => r.quando.day), [27, 21]);
    expect(semanas[1].inicio, DateTime(2026, 9, 14));
    expect(semanas[2].inicio, DateTime(2026, 8, 31));
  });

  test('domingo 23h fica na semana dele; segunda 00h01 abre outra', () {
    final semanas = agruparHistoricoPorSemana(
      [
        _sessao(DateTime(2026, 9, 21, 0, 1)),
        _sessao(DateTime(2026, 9, 20, 23)),
      ],
      now: _now,
      temMais: false,
    );
    expect(semanas, hasLength(2));
    expect(semanas.first.tipo, HistoricoSemanaTipo.atual);
    expect(semanas.last.tipo, HistoricoSemanaTipo.passada);
  });

  test('sessão aberta e sem data ficam de fora', () {
    final semanas = agruparHistoricoPorSemana(
      [
        _sessao(DateTime(2026, 9, 27, 9), status: 'EM_ANDAMENTO'),
        ExecucaoTreino.fromHistoricoResumoJson({
          'id': 99,
          'treinoId': 1,
          'treinoNome': 'Treino A',
          'status': 'CONCLUIDO',
        }),
      ],
      now: _now,
      temMais: false,
    );
    expect(semanas, isEmpty);
  });

  test('com página seguinte, só a semana mais antiga fica incompleta', () {
    final semanas = agruparHistoricoPorSemana(
      [_sessao(DateTime(2026, 9, 27, 9)), _sessao(DateTime(2026, 9, 15, 9))],
      now: _now,
      temMais: true,
    );
    expect(semanas.map((w) => w.completa), [true, false]);
  });

  test('cabeçalho: contagem só com a semana inteira', () {
    final semanas = agruparHistoricoPorSemana(
      [
        _sessao(DateTime(2026, 9, 27, 9)),
        _sessao(DateTime(2026, 9, 22, 9)),
        _sessao(DateTime(2026, 9, 15, 9)),
        _sessao(DateTime(2026, 9, 3, 9)),
      ],
      now: _now,
      temMais: true,
    );
    expect(historicoSemanaCabecalho(_s, semanas[0]), 'Esta semana · 2 treinos');
    expect(
      historicoSemanaCabecalho(_s, semanas[1]),
      'Semana passada · 1 treino',
    );
    expect(
      historicoSemanaCabecalho(_s, semanas[2]),
      startsWith('Semana de 31'),
    );
    expect(historicoSemanaCabecalho(_s, semanas[2]), isNot(contains('·')));
  });
}
