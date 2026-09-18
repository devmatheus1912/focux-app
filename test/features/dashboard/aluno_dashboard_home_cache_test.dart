import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_dashboard_home_client_cache.dart';

void main() {
  tearDown(AlunoDashboardHomeClientCache.clear);

  test('AlunoDashboardHomeClientCache TTL e SWR', () {
    final now = DateTime.utc(2026, 9, 18, 12);
    final bundle = _minimalAlunoHome();
    AlunoDashboardHomeClientCache.put(bundle, now: now);

    expect(
      AlunoDashboardHomeClientCache.getIfFresh(now: now.add(const Duration(seconds: 30))),
      isNotNull,
    );
    expect(
      AlunoDashboardHomeClientCache.getIfFresh(now: now.add(const Duration(seconds: 61))),
      isNull,
    );
    expect(
      AlunoDashboardHomeClientCache.getEvenIfStale(
        now: now.add(const Duration(minutes: 2)),
      ),
      isNotNull,
    );
    expect(
      AlunoDashboardHomeClientCache.getEvenIfStale(
        now: now.add(const Duration(minutes: 6)),
      ),
      isNull,
    );
  });

  test('fromJson prefere historicoResumo ao historico completo', () {
    final bundle = AlunoDashboardHomeBundle.fromJson({
      'aluno': {
        'id': 1,
        'nome': 'Ana',
        'email': 'ana@test.com',
        'status': 'ATIVO',
      },
      'personalBrand': {},
      'treinos': [],
      'historico': [
        {
          'id': 99,
          'treinoId': 1,
          'treinoNome': 'FULL DETAIL',
          'status': 'CONCLUIDO',
          'exercicios': [
            {
              'id': 1,
              'treinoExercicioId': 1,
              'exercicioNome': 'Squat',
              'seriesFeitas': 3,
              'concluido': true,
              'dor': false,
              'seriesDetalhes': [],
              'seriesAnteriores': [],
            },
          ],
        },
      ],
      'historicoResumo': [
        {
          'id': 7,
          'treinoId': 2,
          'treinoNome': 'Resumo',
          'status': 'CONCLUIDO',
          'iniciadoEm': '2026-09-18T10:00:00Z',
          'concluidoEm': '2026-09-18T11:00:00Z',
          'exerciciosCount': 4,
        },
      ],
      'medidas': [],
      'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
      'notificacoesNaoLidas': 0,
      'coachMensagens': [],
    });

    expect(bundle.historico, hasLength(1));
    expect(bundle.historico.first.treinoNome, 'Resumo');
    expect(bundle.historico.first.exercicios, isEmpty);
    expect(bundle.historico.first.id, 7);
  });

  test('fallback historico dump: slim + cap 12', () {
    final items = List.generate(
      20,
      (i) => {
        'id': i + 1,
        'treinoId': i + 1,
        'treinoNome': 'T$i',
        'status': 'CONCLUIDO',
        'exercicios': [
          {
            'id': 1,
            'treinoExercicioId': 1,
            'exercicioNome': 'Squat',
            'seriesFeitas': 3,
            'concluido': true,
            'dor': false,
            'seriesDetalhes': [],
            'seriesAnteriores': [],
          },
        ],
      },
    );
    final bundle = AlunoDashboardHomeBundle.fromJson({
      'aluno': {'id': 1, 'nome': 'A', 'email': 'a@t.com', 'status': 'ATIVO'},
      'personalBrand': {},
      'treinos': [],
      'historico': items,
      'medidas': [],
      'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
    });
    expect(bundle.historico, hasLength(12));
    expect(bundle.historico.every((e) => e.exercicios.isEmpty), isTrue);
  });

  test('ExecucaoTreino.fromHistoricoResumoJson ignora mídia', () {
    final e = ExecucaoTreino.fromHistoricoResumoJson({
      'id': 1,
      'treinoNome': 'A',
      'status': 'CONCLUIDO',
      'exerciciosCount': 8,
    });
    expect(e.exercicios, isEmpty);
    expect(e.evolucoesPerformance, isEmpty);
  });
}

AlunoDashboardHomeBundle _minimalAlunoHome() {
  return AlunoDashboardHomeBundle.fromJson({
    'aluno': {'id': 1, 'nome': 'A', 'email': 'a@t.com', 'status': 'ATIVO'},
    'personalBrand': {},
    'treinos': [],
    'historico': [],
    'medidas': [],
    'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
  });
}
