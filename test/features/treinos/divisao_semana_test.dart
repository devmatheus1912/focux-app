import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/utils/divisao_catalogo.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';
import 'package:focux_app/features/treinos/widgets/treino_no_lugar.dart';

String _resumo(List<DiaDaSemana> semana) => [
  for (final d in semana)
    d.sessoes.isNotEmpty
        ? '${d.dia}:${d.sessoes.map((s) => s.nome).join('+')}'
        : d.segueSequencia
        ? '${d.dia}:segue'
        : '${d.dia}:-',
].join(' ');

void main() {
  group('divisoesSugeridas', () {
    test('2 a 7 dias têm sugestão, e a primeira é a recomendada', () {
      expect(divisoesSugeridas(2).first.rotulo, 'AB · Full body');
      expect(divisoesSugeridas(3).first.rotulo, 'ABC');
      expect(divisoesSugeridas(4).first.rotulo, 'AB · Superior/Inferior');
      expect(divisoesSugeridas(5).first.rotulo, 'ABC');
      expect(divisoesSugeridas(6).first.rotulo, 'ABC · Empurrar/Puxar/Pernas');
      expect(divisoesSugeridas(7).first.rotulo, 'ABC');
      expect(divisoesSugeridas(1), isEmpty);
    });

    test('nenhuma sugerida tem mais letras que dias', () {
      for (var dias = 2; dias <= 7; dias++) {
        for (final d in [...divisoesSugeridas(dias), ...outrasDivisoes(dias)]) {
          expect(d.letras, lessThanOrEqualTo(dias), reason: '${d.rotulo} em $dias dias');
        }
      }
    });

    test('nomes vêm do modelo de exercícios', () {
      expect(divisoesSugeridas(5).first.sessoes, [
        'A · Peito e tríceps',
        'B · Costas e bíceps',
        'C · Pernas e glúteo',
      ]);
      expect(divisoesSugeridas(4).first.sessoes, ['A · Superior', 'B · Inferior']);
      expect(divisoesSugeridas(2).first.sessoes, ['Treino A', 'Treino B']);
      expect(divisoesSugeridas(2)[1].sessoes, ['Full body']);
      expect(divisoesSugeridas(5)[2].sessoes, ['Treino A', 'Treino B', 'Treino C', 'Treino D', 'Treino E']);
    });

    test('outras divisões trazem as de foco', () {
      final outras = outrasDivisoes(3).map((d) => d.rotulo);
      expect(outras, containsAll(['Glúteo e pernas', 'Torso e braços', 'Mobilidade + força', 'Em casa']));
      expect(outrasDivisoes(3).firstWhere((d) => d.rotulo == 'Glúteo e pernas').sessoes, [
        'Inferior A',
        'Inferior B',
      ]);
    });
  });

  group('semanaPorDivisao', () {
    test('ABC em 5 dias: três sessões e dois dias que seguem', () {
      expect(
        _resumo(semanaPorDivisao(const [1, 2, 3, 4, 5], divisoesSugeridas(5).first)),
        '1:A · Peito e tríceps 2:B · Costas e bíceps 3:C · Pernas e glúteo 4:segue 5:segue 6:- 7:-',
      );
    });

    test('dias fora de ordem e com folga no meio', () {
      expect(
        _resumo(semanaPorDivisao(const [5, 1, 3, 6], umaPorDia(2))),
        '1:Treino A 2:- 3:Treino B 4:- 5:segue 6:segue 7:-',
      );
    });

    test('uma letra por dia continua igual ao antigo semanaPorFrequencia', () {
      expect(
        _resumo(semanaPorFrequencia(4)),
        '1:Treino A 2:Treino B 3:- 4:Treino C 5:Treino D 6:- 7:-',
      );
    });
  });

  group('segue a sequência na leitura da fila', () {
    RotinaItem treino(int id, String nome, int? dia) =>
        RotinaItem(id: id, tipo: RotinaItemTipo.treino, treinoId: id, nome: nome, diaSemana: dia);

    test('ficha gravada pela semana: dia fora do aviso segue a sequência', () {
      final fila = RotinaFila(
        itens: [treino(1, 'A', 1), treino(2, 'B', 2), treino(3, 'C', 3)],
        diasAviso: const {6, 7},
      );
      expect(_resumo(semanaDaFila(fila)), '1:A 2:B 3:C 4:segue 5:segue 6:- 7:-');
    });

    test('fila antiga sem dia não ganha dias que seguem', () {
      final fila = RotinaFila(itens: [treino(1, 'A', null), treino(2, 'B', null)]);
      final semana = semanaDaFila(fila);
      expect(semana.where((d) => d.segueSequencia), isEmpty);
    });

    test('estado conta os dias que seguem como dias de treino', () {
      final fila = RotinaFila(
        itens: [treino(1, 'A', 1), treino(2, 'B', 2)],
        diasAviso: const {5, 6, 7},
      );
      final estado = estadoDaFicha(semanaDaFila(fila));
      expect(estado.dias, 4);
      expect(estado.sessoes, 2);
    });
  });

  group('alternarTreinoDescanso', () {
    final base = semanaPorDivisao(const [1, 2, 3], umaPorDia(2));

    test('descanso vira segue e segue vira descanso', () {
      final comQuinta = alternarTreinoDescanso(base, 4);
      expect(comQuinta[3].segueSequencia, isTrue);
      final semQuarta = alternarTreinoDescanso(base, 3);
      expect(semQuarta[2].descanso, isTrue);
      expect(semQuarta[2].segueSequencia, isFalse);
    });

    test('dia com sessão não muda', () {
      expect(_resumo(alternarTreinoDescanso(base, 1)), _resumo(base));
    });
  });

  test('mover para um dia que segue troca de lugar com ele', () {
    final base = semanaPorDivisao(const [1, 2, 3], umaPorDia(2));
    final movida = moverDia(base, de: 1, para: 3);
    expect(_resumo(movida), '1:segue 2:Treino B 3:Treino A 4:- 5:- 6:- 7:-');
  });

  group('sugestaoDaSessao', () {
    test('nome com foco acha o dia do modelo', () {
      final b = sugestaoDaSessao('B · Costas e bíceps');
      expect(b?.$1.id, 'bro-split');
      expect(b?.$2, 1);
      expect(sugestaoDaSessao('A · Superior')?.$1.id, 'upper-lower');
      expect(sugestaoDaSessao('Inferior B')?.$2, 1);
      expect(sugestaoDaSessao('Full body')?.$2, 0);
    });

    test('nome genérico ou desconhecido não casa', () {
      expect(sugestaoDaSessao('Treino B'), isNull);
      expect(sugestaoDaSessao('Peito do João'), isNull);
      expect(sugestaoDaSessao(''), isNull);
    });
  });

  group('sessões no lugar', () {
    List<DiaDaSemana> semana() => [
      DiaDaSemana(dia: 1, sessoes: const [SessaoDaSemana(treinoId: 1, nome: 'A', exerciciosCount: 3)]),
      DiaDaSemana(dia: 2, sessoes: const [SessaoDaSemana(treinoId: 2, nome: 'B', exerciciosCount: 0)]),
      DiaDaSemana(
        dia: 3,
        sessoes: const [
          SessaoDaSemana(treinoId: 3, nome: 'C', exerciciosCount: 0),
          SessaoDaSemana(treinoId: 4, nome: 'C2', exerciciosCount: 2),
        ],
      ),
      for (var d = 4; d <= 7; d++) DiaDaSemana(dia: d, descanso: true),
    ];

    test('próxima vazia segue a ordem e volta ao início', () {
      expect(proximaSessaoVazia(semana(), 1)?.nome, 'B');
      expect(proximaSessaoVazia(semana(), 2)?.nome, 'C');
      expect(proximaSessaoVazia(semana(), 4)?.nome, 'B');
      expect(proximaSessaoVazia(semana(), 99), isNull);
    });

    test('tirar a sessão: o dia que fica vazio vira descanso', () {
      final semB = semanaSemASessao(semana(), 2);
      expect(semB[1].descanso, isTrue);
      expect(semB[1].sessoes, isEmpty);
      final semC = semanaSemASessao(semana(), 3);
      expect(semC[2].sessoes.single.nome, 'C2');
    });
  });
}
