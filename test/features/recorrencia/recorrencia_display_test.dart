import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/features/recorrencia/utils/recorrencia_display.dart';

void main() {
  test('recorrenciaAlunoLabel não expõe id', () {
    expect(recorrenciaAlunoLabel('Ana'), 'Ana');
    expect(recorrenciaAlunoLabel('  '), 'Aluno');
    expect(recorrenciaAlunoLabel(null), 'Aluno');
  });

  test('recorrenciaStatusLabel em PT-BR', () {
    expect(recorrenciaStatusLabel('PENDENTE'), 'Pendente');
    expect(recorrenciaStatusLabel('ativa'), 'Ativa');
    expect(recorrenciaStatusLabel('CANCELADA'), 'Cancelada');
    expect(recorrenciaStatusLabel(''), 'Sem status');
    expect(recorrenciaStatusLabel(null), 'Sem status');
  });

  test('recorrenciaSubtitle e valor', () {
    expect(
      recorrenciaSubtitle(status: 'ATIVA', proximaCobranca: '2026-10-01'),
      'Ativa · Próx: 2026-10-01',
    );
    expect(recorrenciaSubtitle(status: 'PENDENTE'), 'Pendente');
    expect(recorrenciaValorLabel(FxMoney.parse(199)), 'R\$ 199,00');
  });

  test('recorrencia ícone e checkout', () {
    expect(recorrenciaFxIcon('ATIVA'), 'circle-check');
    expect(recorrenciaFxIcon('CANCELADA'), 'alert-triangle');
    expect(recorrenciaFxIcon('PENDENTE'), 'coin');
    expect(recorrenciaDanger('CANCELADA'), isTrue);
    expect(recorrenciaDanger('ATIVA'), isFalse);
    expect(recorrenciaPendente('PENDENTE'), isTrue);
    expect(recorrenciaTemLinkCheckout('PENDENTE', 'https://mp.example'), isTrue);
    expect(recorrenciaTemLinkCheckout('ATIVA', 'https://mp.example'), isFalse);
    expect(recorrenciaTemLinkCheckout('PENDENTE', '  '), isFalse);
  });

  test('recorrencia aluno sticky e subtitle', () {
    expect(
      recorrenciaAlunoStickyLabel(podeAutorizar: true),
      'Autorizar pagamento',
    );
    expect(
      recorrenciaAlunoStickyLabel(podeAutorizar: false),
      'Falar com o personal',
    );
    expect(
      recorrenciaAlunoHubSubtitle(proximaCobranca: '2026-10-01', freshness: 'há 1 min'),
      'Próxima: 2026-10-01 · há 1 min',
    );
    expect(recorrenciaAlunoEmptySubtitle(null), 'Ainda sem cobrança automática');
  });

  test('recorrenciaHubSubtitle junta freshness', () {
    expect(recorrenciaHubSubtitle(null), 'Assinaturas Mercado Pago');
    expect(
      recorrenciaHubSubtitle('há 1 min'),
      'Assinaturas Mercado Pago · há 1 min',
    );
  });
}
