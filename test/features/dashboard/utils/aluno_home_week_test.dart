import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_week.dart';

void main() {
  group('buildAlunoWeekSummary', () {
    test('com meta, sequência e volume', () {
      final w = buildAlunoWeekSummary(
        concluidosSemanaIso: 2,
        frequenciaDias: 3,
        streakAtual: 4,
        volumeSemanaKg: 3200,
      );
      expect(w.feitos, 2);
      expect(w.meta, 3);
      expect(w.streakSemanas, 4);
      expect(w.volumeKg, 3200);
      expect(w.isEmpty, isFalse);
    });

    test('sem meta mantém as sessões', () {
      final w = buildAlunoWeekSummary(
        concluidosSemanaIso: 2,
        frequenciaDias: null,
        streakAtual: 0,
        volumeSemanaKg: 0,
      );
      expect(w.feitos, 2);
      expect(w.meta, isNull);
    });

    test('backend antigo sem sessões esconde o x de y', () {
      final w = buildAlunoWeekSummary(
        concluidosSemanaIso: null,
        frequenciaDias: 3,
        streakAtual: 2,
        volumeSemanaKg: 900,
      );
      expect(w.feitos, isNull);
      expect(w.meta, isNull);
      expect(w.streakSemanas, 2);
    });

    test('volume zero some e sequência negativa vira zero', () {
      final w = buildAlunoWeekSummary(
        concluidosSemanaIso: 0,
        frequenciaDias: 3,
        streakAtual: -1,
        volumeSemanaKg: 0,
      );
      expect(w.volumeKg, isNull);
      expect(w.streakSemanas, 0);
    });

    test('sem nenhum dado fica vazio', () {
      final w = buildAlunoWeekSummary(
        concluidosSemanaIso: null,
        frequenciaDias: null,
        streakAtual: 0,
        volumeSemanaKg: 0,
      );
      expect(w.isEmpty, isTrue);
    });

    test('só a sequência não forma a faixa de 2 métricas', () {
      final w = buildAlunoWeekSummary(
        concluidosSemanaIso: null,
        frequenciaDias: 3,
        streakAtual: 5,
        volumeSemanaKg: 0,
      );
      expect(w.isEmpty, isTrue);
    });
  });
}
