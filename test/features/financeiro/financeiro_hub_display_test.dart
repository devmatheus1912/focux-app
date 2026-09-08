import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_hub_display.dart';

void main() {
  test('financeiroHubViewLabel e subtitle', () {
    expect(financeiroHubViewLabel(FinanceiroHubView.resumo), 'Resumo');
    expect(
      financeiroHubViewLabel(FinanceiroHubView.mensalidades),
      'Mensalidades',
    );
    expect(financeiroHubViewLabel(FinanceiroHubView.metricas), 'Métricas');
    expect(
      financeiroHubSubtitle(view: FinanceiroHubView.resumo, freshness: null),
      'Resumo',
    );
    expect(
      financeiroHubSubtitle(
        view: FinanceiroHubView.metricas,
        freshness: 'há 1 min',
      ),
      'Métricas · há 1 min',
    );
  });

  test('financeiroAlunoHubSubtitle junta count e freshness', () {
    expect(
      financeiroAlunoHubSubtitle(lancamentos: 0, freshness: null),
      '0 lançamentos',
    );
    expect(
      financeiroAlunoHubSubtitle(lancamentos: 1, freshness: 'há 1 min'),
      '1 lançamento · há 1 min',
    );
  });

  test('financeiroAlunoContextLabel nunca expõe id', () {
    expect(
      financeiroAlunoContextLabel('Ana Silva'),
      'Mensalidades de Ana Silva',
    );
    expect(financeiroAlunoContextLabel(null), 'Mensalidades deste aluno');
    expect(financeiroAlunoContextLabel('  '), 'Mensalidades deste aluno');
  });

  test('financeiroMensalidadeSubtitle', () {
    expect(
      financeiroMensalidadeSubtitle('ATRASADO', '2026-09-01'),
      'Atrasado · 2026-09',
    );
    expect(financeiroMensalidadeSubtitle('PAGO', ''), 'Pago · Sem mês');
  });

  test('financeiroMensalidadeHubSubtitle junta mês e freshness', () {
    expect(
      financeiroMensalidadeHubSubtitle(mes: 'Setembro 2026'),
      'Setembro 2026',
    );
    expect(
      financeiroMensalidadeHubSubtitle(
        mes: 'Setembro 2026',
        freshness: 'Atualizado agora',
      ),
      'Setembro 2026 · Atualizado agora',
    );
  });

  test('financeiroMensalidadeMesPorExtenso e tipo de contato', () {
    expect(
      financeiroMensalidadeMesPorExtenso('2026-09-01'),
      'Setembro 2026',
    );
    expect(financeiroContatoTipoLabel('WHATSAPP'), 'WhatsApp');
    expect(financeiroContatoTipoLabel('LIGACAO'), 'Ligação');
  });

  test('financeiroMesOpcoes começa no próximo mês', () {
    final ops = financeiroMesOpcoes(
      agora: DateTime(2026, 9, 1),
      quantidade: 3,
    );
    expect(ops, hasLength(3));
    expect(ops[0].key, '2026-10');
    expect(ops[0].label, 'Outubro 2026');
    expect(ops[1].key, '2026-09');
    expect(ops[2].key, '2026-08');
    expect(financeiroMesTitulo(9, 2026), 'Setembro 2026');
  });

  test('mês de referência injeta o atual se estiver fora da janela', () {
    final ops = financeiroMesReferenciaOpcoes(
      atual: '2024-01-01',
      agora: DateTime(2026, 9, 1),
    );
    expect(ops.first.key, '2024-01');
    expect(financeiroMesReferenciaKey('2026-09-01'), '2026-09');
    expect(financeiroMesReferenciaIso('2026-09'), '2026-09-01');
  });

  test('copy das sheets de lançar e salvar', () {
    expect(financeiroSalvarMensalidadeConfirmTitle(), 'Salvar mensalidade?');
    expect(financeiroLancarMensalidadeConfirmTitle(), 'Lançar mensalidade?');
    expect(financeiroSalvarMensalidadeTileLabel(), 'Salvar');
    expect(financeiroLancarMensalidadeTileLabel(), 'Lançar');
    expect(financeiroMesPickerValue(''), 'Selecionar');
    expect(financeiroMesPickerValue('2026-09-01'), 'Setembro 2026');
    expect(financeiroAlunoPickerValue(null), 'Selecionar');
    expect(financeiroAlunoPickerValue('Ana'), 'Ana');
  });

  test('lote pago só em mensalidade aberta', () {
    expect(financeiroStatusAberto('ATRASADO'), isTrue);
    expect(financeiroStatusAberto('PENDENTE'), isTrue);
    expect(financeiroStatusAberto('pago'), isFalse);
    expect(
      financeiroLotePagoChipLabel(modoSelecao: false, selecionados: 0),
      'Marcar lote',
    );
    expect(
      financeiroLotePagoChipLabel(modoSelecao: true, selecionados: 2),
      'Marcar 2 pagos',
    );
    expect(
      financeiroLotePagoConfirmMessage(1),
      contains('deste aluno'),
    );
  });

  test('financeiroMensalidadeVencimentoLabel prefere o campo do contrato', () {
    expect(
      financeiroMensalidadeVencimentoLabel(mesReferencia: '2026-09-01'),
      'Setembro 2026',
    );
    expect(
      financeiroMensalidadeVencimentoLabel(
        mesReferencia: '2026-09-01',
        vencimento: '2026-10-01',
      ),
      '01/10/2026',
    );
  });

  test('financeiroVencimentoOpcoes cobre o mês e o atual', () {
    final ops = financeiroVencimentoOpcoes(
      mesReferencia: '2026-06-01',
      atual: '2026-06-10',
    );
    expect(
      ops.map((o) => o.iso),
      containsAll(['2026-06-01', '2026-06-05', '2026-06-10', '2026-06-15', '2026-06-30']),
    );
    expect(
      financeiroVencimentoAposTrocaDeMes(
        mesAntigo: '2026-06-01',
        mesNovo: '2026-07-01',
        vencimentoAtual: '2026-06-01',
      ),
      '2026-07-01',
    );
    expect(
      financeiroVencimentoAposTrocaDeMes(
        mesAntigo: '2026-06-01',
        mesNovo: '2026-07-01',
        vencimentoAtual: '2026-06-10',
      ),
      '2026-06-10',
    );
    expect(
      financeiroVencimentoDashboardSubtitle(
        mesReferencia: '2026-06-01',
        vencimento: '2026-06-10',
        status: 'PENDENTE',
      ),
      'Vencendo · 10/06/2026',
    );
  });

  test('financeiroMensalidadePagoEmLabel formata ISO', () {
    expect(financeiroMensalidadePagoEmLabel(null), 'Ainda em aberto');
    expect(financeiroMensalidadePagoEmLabel(''), 'Ainda em aberto');
    expect(
      financeiroMensalidadePagoEmLabel('2026-09-07T12:00:00'),
      '07/09/2026',
    );
  });

  test('financeiro contato do detalhe S3', () {
    expect(financeiroMensalidadeDetalheSecoes, hasLength(2));
    expect(financeiroContatosEmpty(), 'Nenhum contato nesta cobrança');
    expect(
      financeiroContatoSubtitle(null, '2026-09-07T12:00:00'),
      '07/09/2026',
    );
    expect(
      financeiroContatoSubtitle('Ligou e pediu PIX', '2026-09-07T12:00:00'),
      'Ligou e pediu PIX · 07/09/2026',
    );
  });
}
