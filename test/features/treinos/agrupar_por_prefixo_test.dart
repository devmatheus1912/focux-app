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

  test('Supino: "inclinado alto com barra" entra no grupo Supino inclinado', () {
    final grupos = agruparPorPrefixo([
      'Supino inclinado alto com barra',
      'Supino inclinado com barra',
      'Supino inclinado com halteres',
      'Supino inclinado no Smith',
      'Supino no chão com barra (Floor Press)',
    ]);
    expect(grupos.first.prefixo, 'Supino inclinado');
    expect(grupos.first.itens.map((e) => e.$2), [
      'alto com barra',
      'com barra',
      'com halteres',
      'no Smith',
    ]);
    expect(grupos.last.prefixo, isNull);
  });

  test('Flexão de braços: com e sem parêntese viram um grupo só', () {
    final nomes = [
      'Flexão de braços com apoio dos joelhos',
      'Flexão de braços com mãos elevadas (no step)',
      'Flexão de braços declinada (pés elevados)',
      'Flexão de braços diamante',
      'Flexão de braços inclinada (mãos no banco)',
      'Flexão de braços nas argolas ou TRX',
      'Flexão de braços no bosu ou step',
    ];
    final grupos = agruparPorPrefixo(nomes);
    expect(grupos.single.prefixo, 'Flexão de braços');
    expect(grupos.single.itens, hasLength(7));
    expect(grupos.single.itens[3].$2, 'diamante');
  });
}
