import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_ferramentas_logic.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';

String _isoDay(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

void main() {
  group('Aluno360FerramentasLogic', () {
    test('measurementCrossAxisCount switches at 360px', () {
      expect(Aluno360FerramentasLogic.measurementCrossAxisCount(359), 2);
      expect(Aluno360FerramentasLogic.measurementCrossAxisCount(360), 4);
    });

    test('spacing tokens keep sections visually grouped', () {
      expect(Aluno360FerramentasLogic.sectionHeaderGap, lessThan(12));
      expect(Aluno360FerramentasLogic.sectionDividerGap, lessThan(16));
    });

    test('aderenciaSparklineValues maps weekly checkins', () {
      final today = DateTime.now();
      final anchor = DateTime(today.year, today.month, today.day);
      final day0 = anchor.subtract(const Duration(days: 2));
      final day1 = anchor.subtract(const Duration(days: 1));
      final day2 = anchor;

      final raw = [
        {'data': _isoDay(day0), 'checkins': 1},
        {'data': _isoDay(day1), 'checkins': 0},
        {'data': _isoDay(day2), 'checkins': 2},
      ];
      final values = Aluno360FerramentasLogic.aderenciaSparklineValues(raw);
      final padded = padAderenciaWeekToSevenDays([
        AderenciaWeekPoint(checkins: 1, date: _isoDay(day0)),
        AderenciaWeekPoint(checkins: 0, date: _isoDay(day1)),
        AderenciaWeekPoint(checkins: 2, date: _isoDay(day2)),
      ]);
      expect(values, padded.map((p) => p.checkins).toList(growable: false));
    });

    test('aderenciaModuleSub describes weekly context not duplicate percent', () {
      final aluno = Aluno(
        id: 1,
        nome: 'Ana',
        email: 'a@test.com',
        status: 'ATIVO',
        aderenciaPercent: 42,
        diasSemTreino: 10,
      );
      expect(
        Aluno360FerramentasLogic.aderenciaModuleSub(aluno: aluno),
        '10 dias sem treino',
      );

      final today = DateTime.now();
      final anchor = DateTime(today.year, today.month, today.day);

      final semDados = Aluno(
        id: 2,
        nome: 'B',
        email: 'b@test.com',
        status: 'ATIVO',
      );
      expect(
        Aluno360FerramentasLogic.aderenciaModuleSub(
          aluno: semDados,
          aderenciaSemanal: [
            {'data': _isoDay(anchor), 'checkins': 2},
          ],
        ),
        '2 check-ins na semana',
      );
    });

    test('measurementsSummary counts pending fields', () {
      final aluno = Aluno(
        id: 3,
        nome: 'C',
        email: 'c@test.com',
        status: 'ATIVO',
        dataNascimento: '1998-01-15',
      );
      expect(
        Aluno360FerramentasLogic.measurementsPendingCount(aluno: aluno),
        3,
      );
      expect(
        Aluno360FerramentasLogic.measurementsSummary(aluno: aluno),
        '3 de 4 campos pendentes',
      );
    });

    test('aderenciaSparkSemanticsLabel names each weekday', () {
      final today = DateTime.now();
      final anchor = DateTime(today.year, today.month, today.day);
      final raw = [
        {'data': _isoDay(anchor.subtract(const Duration(days: 1))), 'checkins': 1},
        {'data': _isoDay(anchor), 'checkins': 0},
      ];
      final label = Aluno360FerramentasLogic.aderenciaSparkSemanticsLabel(raw);
      expect(label, startsWith('Aderência semanal:'));
      expect(label, contains(weekdayNameFromIso(_isoDay(anchor))));
    });
  });
}
