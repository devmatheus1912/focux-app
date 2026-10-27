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

  test('filtros de recorrência', () {
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
