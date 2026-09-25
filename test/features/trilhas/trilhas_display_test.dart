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
  test('trilhaMetaTipoLabel em PT-BR', () {
    expect(trilhaMetaTipos, ['TREINOS', 'PESO', 'MEDIDA', 'CUSTOMIZADO']);
    expect(trilhaMetaTipoLabel('TREINOS'), 'Número de treinos');
    expect(trilhaMetaTipoLabel('peso'), 'Meta de peso');
    expect(trilhaMetaTipoLabel('MEDIDA'), 'Meta de medida');
    expect(trilhaMetaTipoLabel('CUSTOMIZADO'), 'Customizado');
    expect(trilhaMetaTipoLabel(''), 'Tipo de meta');
    expect(trilhaMetaTipoLabel(null), 'Tipo de meta');
    expect(trilhaMetaTipoLabel('OUTRO'), 'OUTRO');
  });

  test('trilha status, percentual e hub subtitle', () {
    expect(trilhaStatusLabel(true), 'Concluída');
    expect(trilhaStatusLabel(false), 'Em andamento');
    expect(trilhaPercentLabel(70.4), '70%');
    expect(trilhaHubSubtitle(alunoNome: 'Ana'), 'Ana');
    expect(trilhaHubSubtitle(alunoNome: '  '), 'Aluno');
  });

  test('trilha métricas, filtro e parse', () {
    const pendente = MarcoModel(
      id: 1,
      titulo: 'Semana 1',
      ordem: 1,
      concluido: false,
    );
    const feito = MarcoModel(
      id: 2,
      titulo: 'Semana 2',
      ordem: 2,
      concluido: true,
    );
    final ativas = [
      _trilha(id: 1, percentual: 40, marcos: const [pendente, feito]),
      _trilha(id: 2, concluida: true, percentual: 100),
    ];
    expect(trilhaAtivasCount(ativas), 1);
    expect(trilhaConcluidasCount(ativas), 1);
    expect(trilhaMarcosPendentes(ativas), 1);
    expect(trilhaProgressoMedioLabel(ativas), '70%');
    expect(trilhaFiltradas(ativas, trilhaFiltroAndamento).single.id, 1);
    expect(trilhaFiltradas(ativas, trilhaFiltroConcluidas).single.id, 2);
    expect(trilhaProximoMarco(ativas.first)?.id, 1);
    expect(trilhaParseNumero('12,5'), 12.5);
    expect(trilhaMarcosTitulos(['  a  ', '', 'b']), ['a', 'b']);
    expect(trilhaMetaValorHint('TREINOS'), 'Quantos treinos fecham a meta');
    expect(
      trilhaValorAtualLabel(
        _trilha(id: 3, valorAtual: 4, metaValor: 10),
      ),
      '4 / 10',
    );
    expect(trilhaValorUnidade('PESO'), ' kg');
    expect(trilhaValorUnidade('MEDIDA'), ' cm');
    expect(trilhaValorUnidade('TREINOS'), '');
    expect(
      trilhaValorAtualLabel(
        TrilhaModel(
          id: 4,
          alunoId: 1,
          titulo: 'Peso',
          metaTipo: 'PESO',
          valorAtual: 72.5,
          percentualConclusao: 40,
          concluida: false,
          marcos: const [],
          metaValor: 70,
        ),
      ),
      '72,5 / 70 kg',
    );
  });

  test('trilha prazo e datas do contrato', () {
    expect(trilhaParseData('2026-09-20'), DateTime(2026, 9, 20));
    expect(trilhaDataLabel(DateTime(2026, 9, 8)), '08/09');
    expect(trilhaPrazoOpcaoLabel(null), 'Sem prazo');
    expect(trilhaPrazoOpcaoLabel(30), 'Em 30 dias');
    expect(trilhaPrazoIso(null, DateTime(2026, 9, 8)), isNull);
    expect(trilhaPrazoIso(7, DateTime(2026, 9, 8)), '2026-09-15');
    final comPrazo = [
      _trilha(id: 1),
      TrilhaModel(
        id: 2,
        alunoId: 1,
        titulo: 'T2',
        metaTipo: 'TREINOS',
        valorAtual: 0,
        percentualConclusao: 10,
        concluida: false,
        marcos: const [],
        dataFim: '2026-09-20',
      ),
      TrilhaModel(
        id: 3,
        alunoId: 1,
        titulo: 'T3',
        metaTipo: 'TREINOS',
        valorAtual: 10,
        percentualConclusao: 100,
        concluida: true,
        marcos: const [],
        dataFim: '2026-09-10',
      ),
    ];
    expect(trilhaPrazoMetricValue(comPrazo), '20/09');
    expect(trilhaPrazoMetricHint(comPrazo), 'Próximo prazo das ativas');
    expect(trilhaPrazoMetricValue([_trilha(id: 1)]), '—');
    expect(trilhaPrazoMetricHint([_trilha(id: 1)]), 'Sem prazo nas ativas');
    expect(
      trilhaListaAtivas(
        const TrilhaLista(items: [], ativas: 3, hasMore: true),
      ),
      3,
    );
    expect(
      trilhaListaProgressoLabel(
        const TrilhaLista(items: [], progressoMedio: 42),
      ),
      '42%',
    );
    expect(
      trilhaListaPrazoValue(
        const TrilhaLista(items: [], proximoPrazo: '2026-09-20'),
      ),
      '20/09',
    );
    expect(
      trilhaCardContexto(
        TrilhaModel(
          id: 4,
          alunoId: 1,
          titulo: 'T4',
          metaTipo: 'TREINOS',
          valorAtual: 2,
          percentualConclusao: 20,
          concluida: false,
          marcos: const [],
          metaValor: 10,
          dataFim: '2026-09-20',
        ),
      ),
      'Número de treinos · 2 / 10 · até 20/09',
    );
  });
}
