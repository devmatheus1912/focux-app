import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_ferramentas_logic.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';

String _isoDay(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

void main() {
  group('Aluno360FerramentasLogic', () {
    test('spacing tokens keep sections visually grouped', () {
      expect(Aluno360FerramentasLogic.sectionHeaderGap, lessThan(12));
      expect(Aluno360FerramentasLogic.sectionDividerGap, greaterThan(16));
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

    test('measurementRows lists each field with pending state', () {
      final aluno = Aluno(
        id: 3,
        nome: 'C',
        email: 'c@test.com',
        status: 'ATIVO',
        dataNascimento: '1998-01-15',
      );
      final rows = Aluno360FerramentasLogic.measurementRows(aluno: aluno);
      expect(rows, hasLength(4));
      expect(rows[0].label, 'Idade');
      expect(rows[0].complete, isTrue);
      expect(rows[1].complete, isFalse);
      expect(rows[1].value, 'Pendente');
      expect(
        Aluno360FerramentasLogic.measurementsPendingCount(aluno: aluno),
        3,
      );
      expect(
        Aluno360FerramentasLogic.measurementsSummary(aluno: aluno),
        '3 de 4 campos pendentes',
      );
    });

    test('composicaoCorporalValue and anamneseValue use consistent labels', () {
      expect(
        Aluno360FerramentasLogic.composicaoCorporalValue(),
        'Pendente',
      );
      expect(
        Aluno360FerramentasLogic.composicaoCorporalValue(bf: '18.2'),
        'Parcial',
      );
      expect(
        Aluno360FerramentasLogic.composicaoCorporalValue(
          bf: '18.2',
          massaMagra: '52.0',
        ),
        'OK',
      );
      expect(Aluno360FerramentasLogic.anamneseValue('REVISADA'), 'OK');
      expect(Aluno360FerramentasLogic.anamneseValue('PREENCHIDA'), 'Revisar');
      expect(Aluno360FerramentasLogic.anamneseValue('SOLICITADA'), 'Pendente');
      expect(Aluno360FerramentasLogic.anamneseNeedsAttention('PREENCHIDA'), isTrue);
      expect(Aluno360FerramentasLogic.anamneseNeedsAttention('REVISADA'), isFalse);
    });

    test('measurements complete and gated modules helpers', () {
      final aluno = Aluno(
        id: 4,
        nome: 'D',
        email: 'd@test.com',
        status: 'ATIVO',
        dataNascimento: '1990-01-01',
        altura: 1.72,
      );
      expect(
        Aluno360FerramentasLogic.measurementsAllComplete(
          aluno: aluno,
          bf: '20.0',
          massaMagra: '50.0',
        ),
        isTrue,
      );
      expect(
        Aluno360FerramentasLogic.measurementsCompleteSummary(
          aluno: aluno,
          bf: '20.0',
          massaMagra: '50.0',
        ),
        'Gordura 20.0% · Massa magra 50.0 kg',
      );
      expect(
        Aluno360FerramentasLogic.isGatedModuleLocked(
          features: PlanoFeatures.free,
          module: Aluno360FerramentasGatedModule.iaProgresso,
        ),
        isTrue,
      );
      expect(
        Aluno360FerramentasLogic.isGatedModuleLocked(
          features: PlanoFeatures.optimisticEnterprise,
          module: Aluno360FerramentasGatedModule.feedbackVideo,
        ),
        isFalse,
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

    test('splitModulesForFold keeps hot modules and caps fold size', () {
      final aluno = Aluno(
        id: 1,
        nome: 'Ana',
        email: 'ana@test.com',
        status: 'ATIVO',
        statusFinanceiro: 'INADIMPLENTE',
        aderenciaPercent: 0,
        diasSemTreino: 10,
      );
      final split = Aluno360FerramentasLogic.splitModulesForFold(
        aluno: aluno,
        bf: null,
        massaMagra: null,
        anamneseStatus: 'PREENCHIDA',
        aderenciaSemanal: const [],
      );
      expect(
        split.fold.length,
        lessThanOrEqualTo(Aluno360FerramentasLogic.foldModuleLimit),
      );
      expect(split.overflow, isNotEmpty);
      expect(
        split.fold,
        isNot(contains(Aluno360FerramentasModule.mensalidades)),
      );
      expect(split.fold, isNot(contains(Aluno360FerramentasModule.treinos)));
      expect(split.fold, isNot(contains(Aluno360FerramentasModule.chat)));
      expect(
        split.fold,
        isNot(contains(Aluno360FerramentasModule.iaProgresso)),
      );
      expect(split.fold, isNot(contains(Aluno360FerramentasModule.aderencia)));
      expect(split.overflow, contains(Aluno360FerramentasModule.mensalidades));
      expect(split.overflow, contains(Aluno360FerramentasModule.treinos));
      expect(
        {...split.fold, ...split.overflow}.length,
        Aluno360FerramentasModule.values.length,
      );
    });

    test('composicaoCorporalPending false when massa filled', () {
      expect(
        Aluno360FerramentasLogic.composicaoCorporalPending(massaMagra: '52.0'),
        isFalse,
      );
      expect(
        Aluno360FerramentasLogic.composicaoCorporalValue(massaMagra: '52.0'),
        'Parcial',
      );
      expect(
        Aluno360FerramentasLogic.composicaoCorporalPending(),
        isTrue,
      );
    });
  });
}
