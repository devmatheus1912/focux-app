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
    expect(recorrenciaStatusLabel('PAUSADA'), 'Pausada');
    expect(recorrenciaStatusLabel('CANCELADA'), 'Cancelada');
    expect(recorrenciaStatusLabel(''), 'Sem status');
    expect(recorrenciaStatusLabel(null), 'Sem status');
  });

  test('recorrenciaSubtitle e valor', () {
    expect(
      recorrenciaSubtitle(status: 'ATIVA', proximaCobranca: '2026-10-01'),
      'Ativa · Vence 01/10',
    );
    expect(recorrenciaAjudaTips.map((t) => t.$1), contains('E as mensalidades?'));
    expect(recorrenciaAjudaSubtitulo, contains('PIX'));
    expect(recorrenciaAjudaTips.map((t) => t.$2).join(), isNot(contains('Mercado Pago')));
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
      recorrenciaAlunoStickyKind(status: 'PENDENTE', initPoint: 'https://mp'),
      RecorrenciaAlunoStickyKind.autorizar,
    );
    expect(
      recorrenciaAlunoStickyKind(status: 'ATIVA'),
      RecorrenciaAlunoStickyKind.pausar,
    );
    expect(
      recorrenciaAlunoStickyKind(status: 'PAUSADA'),
      RecorrenciaAlunoStickyKind.retomar,
    );
    expect(
      recorrenciaAlunoStickyKind(status: null),
      RecorrenciaAlunoStickyKind.chat,
    );
    expect(
      recorrenciaAlunoStickyLabel(RecorrenciaAlunoStickyKind.autorizar),
      'Autorizar pagamento',
    );
    expect(
      recorrenciaAlunoStickyLabel(RecorrenciaAlunoStickyKind.pausar),
      'Pausar cobrança',
    );
    expect(
      recorrenciaAlunoStickyLabel(RecorrenciaAlunoStickyKind.retomar),
      'Retomar cobrança',
    );
    expect(
      recorrenciaAlunoStickyLabel(RecorrenciaAlunoStickyKind.chat),
      'Falar com o personal',
    );
    expect(recorrenciaAlunoHubSubtitle(), 'Cobrança mensal');
    expect(recorrenciaAlunoEmptySubtitle(), 'Ainda sem cobrança automática');
    expect(recorrenciaProximaValue(null), '—');
    expect(recorrenciaProximaValue('2026-10-01'), '01/10');
    expect(
      recorrenciaPagamentoValue(status: 'ATIVA'),
      'Ativa',
    );
    expect(
      recorrenciaPagamentoValue(
        status: 'PENDENTE',
        initPoint: 'https://mp',
      ),
      'Autorizar',
    );
    expect(recorrenciaCicloValue(), 'Mensal');
    expect(recorrenciaProximaHint(null), 'Sem data da próxima cobrança');
    expect(recorrenciaProximaHint('2026-10-01'), 'Próximo vencimento');
    expect(recorrenciaCicloHint(), 'PIX para o personal');
  });

  test('recorrência via PIX: dia de vencimento e ações do personal', () {
    expect(recorrenciaDiaPadrao(DateTime(2026, 9, 30)), 28);
    expect(recorrenciaDiaPadrao(DateTime(2026, 9, 5)), 5);
    expect(recorrenciaDiaLabel(10), 'Todo dia 10');
    expect(recorrenciaAcoesDisponiveis('ATIVA'), [
      RecorrenciaAcao.pausar,
      RecorrenciaAcao.cancelar,
    ]);
    expect(recorrenciaAcoesDisponiveis('PAUSADA').first, RecorrenciaAcao.retomar);
    expect(recorrenciaAcoesDisponiveis('CANCELADA'), isEmpty);
    expect(recorrenciaAcaoPath(RecorrenciaAcao.cancelar), 'cancelar');
  });

  test('recorrenciaCountLabel e filtro', () {
    expect(recorrenciaCountLabel(0), 'Nenhuma assinatura');
    expect(recorrenciaCountLabel(1), '1 assinatura');
    expect(recorrenciaCountLabel(3), '3 assinaturas');
    expect(
      recorrenciaHubFiltroLabel(RecorrenciaHubFiltro.pendente),
      'Pendentes',
    );
    expect(
      recorrenciaHubFiltroStatus(RecorrenciaHubFiltro.ativa),
      'ATIVA',
    );
    expect(recorrenciaHubFiltroStatus(RecorrenciaHubFiltro.todos), isNull);
  });
}
