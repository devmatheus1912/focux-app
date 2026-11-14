import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_hub_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  test('segmentos do Financeiro: rótulos, rota e subtítulo', () {
    final s = lookupS(const Locale('pt'));
    expect(
      [for (final g in FinanceiroSegmento.values) financeiroSegmentoLabel(g, s)],
      ['Mensalidades', 'Recorrências', 'Resultados'],
    );
    expect(financeiroSegmentoDaRota(null), FinanceiroSegmento.mensalidades);
    expect(financeiroSegmentoDaRota('x'), FinanceiroSegmento.mensalidades);
    expect(
      financeiroSegmentoDaRota('recorrencias'),
      FinanceiroSegmento.recorrencias,
    );
    expect(
      financeiroSegmentoDaRota('resultados'),
      FinanceiroSegmento.resultados,
    );
    expect(financeiroHubSubtitle(freshness: 'há 1 min'), 'há 1 min');
    expect(financeiroHubSubtitle(), 'Cobranças e resultados');
  });

  test('lista sem "Atualizar atrasos" e menu do detalhe', () {
    final lote = financeiroListaToolsDoLote();
    expect(lote.foldChip, FinanceiroListaToolId.marcarLote);
    expect(lote.mais, [FinanceiroListaToolId.cancelarLote]);

    final mais = mensalidadeDetailMaisActions(pending: true);
    expect(mais.first, MensalidadeDetailActionId.edit);
    expect(mais.last, MensalidadeDetailActionId.cancelar);
    expect(mais, contains(MensalidadeDetailActionId.contato));
    expect(mais, contains(MensalidadeDetailActionId.aluno));
    expect(mais, isNot(contains(MensalidadeDetailActionId.desfazerPagamento)));
    final paga = mensalidadeDetailMaisActions(pending: false, pago: true);
    expect(paga, contains(MensalidadeDetailActionId.desfazerPagamento));
    expect(paga, isNot(contains(MensalidadeDetailActionId.cancelar)));
    final cancelada = mensalidadeDetailMaisActions(pending: false);
    expect(cancelada, [MensalidadeDetailActionId.aluno]);
    final s = lookupS(const Locale('pt'));
    expect(
      mensalidadeDetailActionLabel(MensalidadeDetailActionId.cancelar, s),
      'Cancelar mensalidade',
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

  test('copy das sheets de lançar e salvar', () {
    expect(financeiroSalvarMensalidadeConfirmTitle(), 'Salvar mensalidade?');
    expect(financeiroLancarMensalidadeConfirmTitle(), 'Lançar mensalidade?');
    expect(financeiroSalvarMensalidadeTileLabel(), 'Salvar');
    expect(financeiroLancarMensalidadeTileLabel(), 'Lançar');
    expect(financeiroAlunoPickerValue(null), 'Selecionar');
    expect(financeiroAlunoPickerValue('Ana'), 'Ana');
  });

  test('lote pago só em mensalidade aberta', () {
    expect(financeiroStatusAberto('ATRASADO'), isTrue);
    expect(financeiroStatusAberto('PENDENTE'), isTrue);
    expect(financeiroStatusAberto('pago'), isFalse);
    expect(financeiroStatusAberto('CANCELADO'), isFalse);
    expect(financeiroMesCabecalho('2026-10-01'), 'Outubro 2026');
    expect(financeiroMesCabecalho('2025-12'), 'Dezembro 2025');
    expect(
      financeiroLotePagoChipLabel(modoSelecao: false, selecionados: 0),
      'Marcar lote',
    );
    expect(
      financeiroLotePagoChipLabel(modoSelecao: true, selecionados: 2),
      'Marcar 2 pagas',
    );
    expect(
      financeiroLotePagoConfirmMessage(1),
      contains('esta cobrança'),
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

  test('financeiroMensalidadePagoEmLabel formata ISO', () {
    expect(financeiroMensalidadePagoEmLabel(null), 'Ainda em aberto');
    expect(financeiroMensalidadePagoEmLabel(''), 'Ainda em aberto');
    expect(
      financeiroMensalidadePagoEmLabel('2026-09-07T12:00:00'),
      '07/09/2026',
    );
  });

}
