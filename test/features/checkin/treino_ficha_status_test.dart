import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/treino_ficha_status.dart';

void main() {
  group('treino_ficha_status', () {
    test('DISPONIVEL pode iniciar', () {
      final treino = ExecucaoTreino(
        treinoId: 1,
        treinoNome: 'A',
        status: 'DISPONIVEL',
        exercicios: const [],
      );
      expect(isTreinoDisponivelParaIniciar(treino), isTrue);
      expect(isTreinoAguardandoLiberacao(treino), isFalse);
    });

    test('AGUARDANDO_LIBERACAO nao oferece iniciar', () {
      final treino = ExecucaoTreino(
        treinoId: 1,
        treinoNome: 'A',
        status: 'AGUARDANDO_LIBERACAO',
        exercicios: const [],
      );
      expect(isTreinoDisponivelParaIniciar(treino), isFalse);
      expect(isTreinoAguardandoLiberacao(treino), isTrue);
    });

    test('legado sem exercicios fica aguardando', () {
      final treino = ExecucaoTreino(
        treinoId: 1,
        treinoNome: 'A',
        status: 'PENDENTE',
        exercicios: const [],
      );
      expect(isTreinoAguardandoLiberacao(treino), isTrue);
      expect(isTreinoDisponivelParaIniciar(treino), isFalse);
    });

    test('ordenacao start-first coloca iniciaveis no topo', () {
      final reservado = ExecucaoTreino(
        treinoId: 1,
        treinoNome: 'Reservado',
        status: 'AGUARDANDO_LIBERACAO',
        exercicios: const [],
      );
      final pronto = ExecucaoTreino(
        treinoId: 2,
        treinoNome: 'Pronto',
        status: 'DISPONIVEL',
        exercicios: const [],
      );
      final ordered = treinosOrdenadosStartFirst([reservado, pronto]);
      expect(ordered.map((t) => t.treinoId), [2, 1]);
    });

    test('consistencia conta dias unicos e nao N execucoes', () {
      final historico = [
        ExecucaoTreino(
          treinoId: 1,
          treinoNome: 'A',
          status: 'CONCLUIDO',
          concluidoEm: '2026-09-08T10:00:00',
          exercicios: const [],
        ),
        ExecucaoTreino(
          treinoId: 1,
          treinoNome: 'A',
          status: 'CONCLUIDO',
          concluidoEm: '2026-09-08T10:00:01',
          exercicios: const [],
        ),
        ExecucaoTreino(
          treinoId: 1,
          treinoNome: 'A',
          status: 'CONCLUIDO',
          concluidoEm: '2026-09-08T10:00:02',
          exercicios: const [],
        ),
      ];
      expect(
        countUniqueCompletedDaysThisWeek(
          historico,
          now: DateTime(2026, 9, 9),
        ),
        1,
      );
    });
  });

  group('AderenciaDia contrato novo', () {
    test('aceita dia/weekday do backend', () {
      final dia = AderenciaDia.fromJson({
        'dia': '2026-09-09',
        'weekday': 'Q',
        'checkins': 1,
      });
      expect(dia.data, '2026-09-09');
      expect(dia.labelDia, 'Q');
      expect(dia.checkins, 1);
    });

    test('bundle hidrata resumo e diasComCheckin', () {
      final bundle = AderenciaSemanalBundle.fromJson({
        'dias': [
          {'dia': '2026-09-09', 'weekday': 'Q', 'checkins': 1},
        ],
        'totalSemana': 7,
        'streakAtual': 1,
        'diasComCheckin': 1,
        'resumo': '1 de 7 dias com check-in',
      });
      final week = summarizeAderenciaWeek(
        parseAderenciaSemanal(bundle.diasMaps),
        bundle: bundle,
      );
      expect(week.weekRatioLabel, '1/7');
      expect(week.caption, '1 de 7 dias com check-in');
      expect(week.hasAnyCheckin, isTrue);
      expect(week.points.where((p) => p.checkins > 0).length, 1);
    });

    test('weekRatioLabel usa 7 dias mesmo quando totalSemana é soma de check-ins', () {
      final bundle = AderenciaSemanalBundle.fromJson({
        'dias': [
          {'dia': '2026-09-11', 'weekday': 'S', 'checkins': 2},
          {'dia': '2026-09-12', 'weekday': 'S', 'checkins': 1},
        ],
        'totalSemana': 3,
        'streakAtual': 2,
        'diasComCheckin': 2,
        'resumo': '2 de 7 dias com check-in',
      });
      final week = summarizeAderenciaWeek(
        parseAderenciaSemanal(bundle.diasMaps),
        bundle: bundle,
      );
      expect(week.weekRatioLabel, '2/7');
      expect(week.caption, '2 de 7 dias com check-in');
    });
  });
}
