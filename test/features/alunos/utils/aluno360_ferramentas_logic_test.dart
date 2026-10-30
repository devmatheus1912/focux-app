import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_ferramentas_grupos.dart';
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
    test('cada ferramenta tem ícone próprio', () {
      final icones = Aluno360FerramentasModule.values
          .map(Aluno360FerramentasLogic.moduleIcon)
          .toSet();
      expect(icones, hasLength(Aluno360FerramentasModule.values.length));
    });

    test('todo módulo tem a sua linha, com ícone, na tela', () {
      final grade = File(
        'lib/features/alunos/widgets/aluno360_ferramentas_grupos_view.dart',
      ).readAsStringSync();
      final linhas = RegExp(
        r'Aluno360FerramentasModule\.\w+ => (linha|_linhaRecorrencia)\(',
      ).allMatches(grade).length;
      expect(linhas, Aluno360FerramentasModule.values.length);
      expect(grade, contains('Aluno360FerramentasLogic.moduleIcon(modulo)'));
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
        '2 check-ins em 7 dias',
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
      expect(Aluno360FerramentasLogic.anamneseNeedsAttention('SOLICITADA'), isFalse);
      expect(Aluno360FerramentasLogic.anamneseNeedsAttention('REVISADA'), isFalse);
    });

    test('módulos bloqueados pelo plano', () {
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
      expect(label, startsWith('Últimos 7 dias:'));
      expect(label, contains(weekdayNameFromIso(_isoDay(anchor))));
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

  group('grupos da aba Ferramentas', () {
    Aluno aluno({
      bool inadimplente = false,
      int? aderencia = 80,
      int? dias = 1,
      String? nascimento = '1990-01-01',
      double? altura = 1.72,
      String? objetivo = 'Hipertrofia',
      String? whatsapp = '11999999999',
    }) => Aluno(
      id: 1,
      nome: 'Ana',
      email: 'ana@test.com',
      status: 'ATIVO',
      inadimplente: inadimplente,
      statusFinanceiro: inadimplente ? 'INADIMPLENTE' : 'EM_DIA',
      aderenciaPercent: aderencia,
      diasSemTreino: dias,
      dataNascimento: nascimento,
      altura: altura,
      objetivo: objetivo,
      whatsapp: whatsapp,
    );

    List<Aluno360FerramentasSecao> secoes(
      Aluno a, {
      String? status = 'REVISADA',
      String? bf = '18,0',
      String? massa = '55,0',
    }) => secoesDeFerramentas(
      aluno: a,
      anamneseStatus: status,
      bf: bf,
      massaMagra: massa,
      aderenciaSemanal: const [],
    );

    test('todo módulo está em exatamente um grupo e nenhum some', () {
      final todos = secoes(aluno()).expand((s) => s.modulos).toList();
      expect(todos.toSet(), Aluno360FerramentasModule.values.toSet());
      expect(todos.length, Aluno360FerramentasModule.values.length);
      for (final m in Aluno360FerramentasModule.values) {
        expect(
          Aluno360FerramentasGrupo.values.where(
            (g) => aluno360ModulosDoGrupo[g]!.contains(m),
          ),
          hasLength(1),
          reason: '$m',
        );
      }
    });

    test('sem nada urgente, a ordem é a fixa', () {
      expect(secoes(aluno()).map((s) => s.grupo), [
        Aluno360FerramentasGrupo.treino,
        Aluno360FerramentasGrupo.acompanhamento,
        Aluno360FerramentasGrupo.relacao,
        Aluno360FerramentasGrupo.dinheiro,
      ]);
    });

    test('mensalidade em atraso faz o grupo Dinheiro subir', () {
      final lista = secoes(aluno(inadimplente: true));
      expect(lista.first.grupo, Aluno360FerramentasGrupo.dinheiro);
      expect(lista.first.atencao, isTrue);
    });

    test('anamnese preenchida (a revisar) faz Acompanhamento subir', () {
      final lista = secoes(aluno(), status: 'PREENCHIDA');
      expect(lista.first.grupo, Aluno360FerramentasGrupo.acompanhamento);
    });

    test('anamnese nunca pedida tem selo mas não reordena', () {
      final a = aluno();
      expect(
        aluno360ModuloPedeAtencao(
          Aluno360FerramentasModule.anamnese,
          aluno: a,
          bf: '18,0',
          massaMagra: '55,0',
          anamneseStatus: null,
          aderenciaSemanal: const [],
        ),
        isTrue,
      );
      expect(secoes(a, status: null).first.grupo, Aluno360FerramentasGrupo.treino);
    });

    test('vários urgentes mantêm a ordem fixa entre si', () {
      final lista = secoes(aluno(inadimplente: true), status: 'PREENCHIDA');
      expect(lista.take(2).map((s) => s.grupo), [
        Aluno360FerramentasGrupo.acompanhamento,
        Aluno360FerramentasGrupo.dinheiro,
      ]);
    });

    test('composição impossível (gordura 818 %) é suspeita e sobe o grupo', () {
      expect(composicaoSuspeita(bf: '818,0', massaMagra: '51,0'), isTrue);
      expect(composicaoSuspeita(bf: '18,0', massaMagra: '55,0'), isFalse);
      expect(
        aluno360ComposicaoValor(bf: '818,0', massaMagra: '51,0'),
        'Confira o valor',
      );
      expect(aluno360ComposicaoValor(bf: '18,0', massaMagra: '55,0'), 'OK');
      expect(
        secoes(aluno(), bf: '818,0', massa: '51,0').first.grupo,
        Aluno360FerramentasGrupo.acompanhamento,
      );
    });

    test('aderência sem histórico mostra "—", não "0%"', () {
      expect(aluno360AderenciaValor(aluno(aderencia: 0, dias: null)), '—');
      expect(aluno360AderenciaValor(aluno(aderencia: 74)), '74%');
    });

    test('dados do aluno: completo e incompleto', () {
      expect(aluno360DadosIncompletos(aluno()), isFalse);
      final incompleto = aluno360DadosDoAluno(aluno(nascimento: null, altura: null));
      expect(incompleto.where((l) => !l.completo).map((l) => l.campo), [
        Aluno360DadoCampo.nascimento,
        Aluno360DadoCampo.altura,
      ]);
      expect(aluno360DadosIncompletos(aluno(altura: null)), isTrue);
    });

    test('dados do aluno trazem o valor pronto para mostrar', () {
      final linhas = aluno360DadosDoAluno(aluno());
      String? valor(Aluno360DadoCampo c) =>
          linhas.firstWhere((l) => l.campo == c).valor;
      expect(valor(Aluno360DadoCampo.altura), '172 cm');
      expect(valor(Aluno360DadoCampo.contato), '11999999999');
      expect(valor(Aluno360DadoCampo.nascimento), endsWith('anos'));
    });
  });
}
