import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/trilhas/models/trilha.dart';
import 'package:focux_app/features/trilhas/utils/trilhas_display.dart';

TrilhaModel _trilha({
  required int id,
  bool concluida = false,
  double percentual = 0,
  List<MarcoModel> marcos = const [],
  double valorAtual = 0,
  double? metaValor,
}) {
  return TrilhaModel(
    id: id,
    alunoId: 1,
    titulo: 'T$id',
    metaTipo: 'TREINOS',
    valorAtual: valorAtual,
    percentualConclusao: percentual,
    concluida: concluida,
    marcos: marcos,
    metaValor: metaValor,
  );
}

void main() {
  MarcoModel m(int id, bool feito, {int? ordem}) =>
      MarcoModel(id: id, titulo: 'M$id', ordem: ordem ?? id, concluido: feito);

  test('resumo da linha: etapa atual e próxima', () {
    expect(
      trilhaResumoLinha(
        _trilha(id: 1, marcos: [m(1, true), m(2, false), m(3, false)]),
      ),
      'Etapa 2 de 3 · Próxima: M2',
    );
    expect(
      trilhaResumoLinha(_trilha(id: 2, marcos: [m(1, true), m(2, true)])),
      'Concluída',
    );
    expect(trilhaResumoLinha(_trilha(id: 3)), 'Sem etapas');
  });

  test('etapa atual respeita a ordem, não a posição na lista', () {
    final t = _trilha(
      id: 1,
      marcos: [m(9, false, ordem: 2), m(8, false, ordem: 1)],
    );
    expect(trilhaEtapaAtual(t)?.id, 8);
  });

  test('prazo: até, venceu e concluída não vence', () {
    final hoje = DateTime(2026, 11, 10);
    TrilhaModel com(String fim, {bool concluida = false}) => TrilhaModel(
      id: 1,
      alunoId: 1,
      titulo: 'T',
      metaTipo: 'ETAPAS',
      valorAtual: 0,
      percentualConclusao: 0,
      concluida: concluida,
      marcos: const [],
      dataFim: fim,
    );
    expect(trilhaPrazoLabel(com('2026-11-30'), hoje), 'até 30/11');
    expect(trilhaPrazoLabel(com('2026-11-01'), hoje), 'venceu 01/11');
    expect(trilhaPrazoVencido(com('2026-11-01'), hoje), isTrue);
    expect(
      trilhaPrazoVencido(com('2026-11-01', concluida: true), hoje),
      isFalse,
    );
    expect(trilhaPrazoLabel(_trilha(id: 1), hoje), isNull);
  });

  test('formulário: nome, de 2 a 10 etapas, vazias ignoradas', () {
    expect(trilhaEtapasValidas([' a ', '', '  ', 'b']), ['a', 'b']);
    expect(trilhaErroFormulario(nome: '', etapas: ['a', 'b']), isNotNull);
    expect(
      trilhaErroFormulario(nome: 'X', etapas: ['a']),
      'Preencha pelo menos 2 etapas.',
    );
    expect(
      trilhaErroFormulario(nome: 'X', etapas: List.filled(11, 'e')),
      isNotNull,
    );
    expect(trilhaErroFormulario(nome: 'X', etapas: ['a', 'b']), isNull);
  });

  test('modelos prontos são válidos e com nomes únicos', () {
    expect(
      trilhaModelos.map((x) => x.nome).toSet().length,
      trilhaModelos.length,
    );
    for (final mod in trilhaModelos) {
      expect(trilhaErroFormulario(nome: mod.nome, etapas: mod.etapas), isNull);
    }
  });

  test('grupos: em andamento e concluídas', () {
    final g = trilhaGrupos([_trilha(id: 1), _trilha(id: 2, concluida: true)]);
    expect(g.andamento.single.id, 1);
    expect(g.concluidas.single.id, 2);
  });

  group('trilhaResumo360', () {
    MarcoModel m(int id, bool feito) =>
        MarcoModel(id: id, titulo: 'M$id', ordem: id, concluido: feito);

    test('sem dado, vazio e só concluídas', () {
      expect(trilhaResumo360(null), 'Etapas e progresso');
      expect(trilhaResumo360(const TrilhaLista(items: [])), 'Nenhuma trilha');
      expect(
        trilhaResumo360(TrilhaLista(items: [_trilha(id: 1, concluida: true)])),
        '1 trilha concluída',
      );
    });

    test('etapa da primeira em andamento e quantas mais', () {
      final lista = TrilhaLista(items: [
        _trilha(id: 1, concluida: true),
        _trilha(id: 2, marcos: [m(1, true), m(2, false), m(3, false)]),
        _trilha(id: 3),
      ]);
      expect(trilhaResumo360(lista), 'T2 · etapa 2 de 3 · +1');
    });

    test('sem marcos usa a porcentagem; todos feitos fica na última', () {
      expect(
        trilhaResumo360(TrilhaLista(items: [_trilha(id: 4, percentual: 40)])),
        'T4 · 40%',
      );
      expect(
        trilhaResumo360(TrilhaLista(items: [
          _trilha(id: 5, marcos: [m(1, true), m(2, true)]),
        ])),
        'T5 · etapa 2 de 2',
      );
    });
  });
}
