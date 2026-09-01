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
}
