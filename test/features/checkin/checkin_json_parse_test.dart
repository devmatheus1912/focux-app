import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/checkin_json.dart';

void main() {
  group('checkinJson helpers', () {
    test('string tolera null, número e vazio', () {
      expect(checkinJsonString(null), isNull);
      expect(checkinJsonString('  '), isNull);
      expect(checkinJsonString(42), '42');
      expect(checkinJsonStringOr(null, 'Treino'), 'Treino');
      expect(checkinJsonStringOr(' A '), 'A');
    });

    test('int tolera string e double', () {
      expect(checkinJsonInt(null), isNull);
      expect(checkinJsonInt(7), 7);
      expect(checkinJsonInt(7.9), 7);
      expect(checkinJsonInt('12'), 12);
      expect(checkinJsonInt('x'), isNull);
      expect(checkinJsonIntOr(null, 3), 3);
    });

    test('double tolera vírgula BR', () {
      expect(checkinJsonDouble(null), isNull);
      expect(checkinJsonDouble(22.5), 22.5);
      expect(checkinJsonDouble('22,5'), 22.5);
      expect(checkinJsonDouble(''), isNull);
    });

    test('bool tolera string e número', () {
      expect(checkinJsonBool(null), isFalse);
      expect(checkinJsonBool(true), isTrue);
      expect(checkinJsonBool(1), isTrue);
      expect(checkinJsonBool('sim'), isTrue);
      expect(checkinJsonBool('não'), isFalse);
      expect(checkinJsonBool('maybe', fallback: true), isTrue);
    });

    test('map list ignora itens inválidos', () {
      expect(checkinJsonMap(null), isNull);
      expect(checkinJsonMap({'a': 1}), {'a': 1});
      expect(
        checkinJsonMapList([
          {'id': 1},
          'x',
          null,
          {'id': 2},
        ]),
        [
          {'id': 1},
          {'id': 2},
        ],
      );
    });
  });

  group('parseExecucaoTreinoPagina', () {
    test('ignora content corrompido e lê cursor', () {
      final pagina = parseExecucaoTreinoPagina({
        'content': [
          {
            'id': '9',
            'treinoId': '3',
            'treinoNome': null,
            'status': 1,
            'exercicios': [
              {
                'id': 1,
                'treinoExercicioId': 2,
                'exercicioNome': null,
                'seriesFeitas': '1',
                'concluido': 'true',
                'gifUrl': 99,
                'dor': 'sim',
              },
              'lixo',
            ],
          },
          'pula',
          {'treinoId': 4, 'status': 'CONCLUIDO'},
        ],
        'hasNext': true,
        'nextCursor': 12345,
        'page': '0',
        'size': '20',
      });

      expect(pagina.content, hasLength(2));
      expect(pagina.content.first.id, 9);
      expect(pagina.content.first.treinoNome, 'Treino');
      expect(pagina.content.first.status, '1');
      expect(pagina.content.first.exercicios, hasLength(1));
      expect(pagina.content.first.exercicios.single.exercicioNome, 'Exercício');
      expect(pagina.content.first.exercicios.single.gifUrl, '99');
      expect(pagina.content.first.exercicios.single.concluido, isTrue);
      expect(pagina.content.first.exercicios.single.dor, isTrue);
      expect(pagina.hasNext, isTrue);
      expect(pagina.nextCursor, '12345');
      expect(pagina.page, 0);
      expect(pagina.size, 20);
    });

    test('falha alto sem content array', () {
      expect(
        () => parseExecucaoTreinoPagina({'itens': []}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('ExecucaoTreino.fromJson não quebra em campos nullable tipados errado', () {
    final treino = ExecucaoTreino.fromJson({
      'id': null,
      'treinoId': '8',
      'treinoNome': 10,
      'status': null,
      'iniciadoEm': 2024,
      'exercicios': const [],
      'evolucoesCarga': [
        {
          'exercicioId': '1',
          'exercicioNome': null,
          'cargaAnteriorKg': '20,0',
          'cargaAtualKg': '22,5',
          'diferencaKg': '2,5',
          'percentual': '10',
          'mensagem': null,
        },
      ],
    });

    expect(treino.id, isNull);
    expect(treino.treinoId, 8);
    expect(treino.treinoNome, '10');
    expect(treino.status, 'PENDENTE');
    expect(treino.iniciadoEm, '2024');
    expect(treino.evolucoesCarga.single.cargaAtualKg, 22.5);
    expect(treino.evolucoesCarga.single.mensagem, '');
  });
}
