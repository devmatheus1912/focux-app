import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/agrupar_por_prefixo.dart';

void main() {
  test('RDL com 12 variantes vira um grupo, cada linha só com o resto', () {
    final nomes = [
      for (final v in [
        'com barra',
        'com halteres',
        'unilateral com halter',
        'no Smith',
        'com kettlebell',
        'com elástico',
        'déficit com barra',
        'na polia',
        'com pausa',
        'unilateral no cabo',
        'com trap bar',
        'sumô com halter',
      ])
        'Levantamento terra romeno (RDL) $v',
    ];
    final grupos = agruparPorPrefixo(nomes);
    expect(grupos, hasLength(1));
    expect(grupos.single.prefixo, 'Levantamento terra romeno (RDL)');
    expect(grupos.single.itens, hasLength(12));
    expect(grupos.single.itens[2], (2, 'unilateral com halter'));
  });

  test('dois resultados com o mesmo começo ficam inteiros', () {
    final grupos = agruparPorPrefixo([
      'Agachamento com barra',
      'Agachamento com halteres',
      'Stiff com barra',
    ]);
    expect(grupos.every((g) => g.prefixo == null), isTrue);
    expect(grupos.expand((g) => g.itens).map((e) => e.$2), [
      'Agachamento com barra',
      'Agachamento com halteres',
      'Stiff com barra',
    ]);
  });

  test('corta no parêntese antes da preposição; soltos em volta do grupo', () {
    expect(prefixoDoNome('Remada (pegada aberta) com barra'), 'Remada (pegada aberta)');
    expect(prefixoDoNome('Agachamento no Smith'), 'Agachamento');
    expect(prefixoDoNome('Burpee'), isNull);
    final grupos = agruparPorPrefixo([
      'Abdominal',
      'Agachamento com barra',
      'Agachamento com halteres',
      'Agachamento no Smith',
      'Burpee',
    ]);
    expect(grupos.map((g) => g.prefixo), [null, 'Agachamento', null]);
    expect(grupos[1].itens.map((e) => e.$2), ['com barra', 'com halteres', 'no Smith']);
    expect(grupos[2].itens.single, (4, 'Burpee'));
  });
}
