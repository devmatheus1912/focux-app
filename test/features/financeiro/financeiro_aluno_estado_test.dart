import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_aluno_estado.dart';
import 'package:focux_app/features/recorrencia/utils/recorrencia_display.dart';

Mensalidade _m(int id, String mes, String status, {String? venc, int valor = 200}) =>
    Mensalidade(
      id: id,
      alunoId: 1,
      alunoNome: 'Julio',
      valor: valor,
      mesReferencia: mes,
      status: status,
      vencimento: venc,
    );

void main() {
  test('tudo em dia: última paga e sem nada para pagar', () {
    final e = financeiroAlunoEstado([
      _m(1, '2026-10', 'PAGO'),
      _m(2, '2026-11', 'PAGO'),
    ], parcial: false);
    expect(e.situacao, FinanceiroAlunoSituacao.emDia);
    expect(e.titulo, 'Tudo em dia');
    expect(e.linha, 'Última paga: novembro de 2026');
    expect(e.paraPagar, isNull);
  });

  test('em aberto no prazo: soma e vencimento mais próximo', () {
    final e = financeiroAlunoEstado([
      _m(1, '2027-01', 'PENDENTE', venc: '2027-01-05'),
      _m(2, '2026-12', 'PENDENTE', venc: '2026-12-05'),
      _m(3, '2026-11', 'PAGO'),
    ], parcial: false);
    expect(e.situacao, FinanceiroAlunoSituacao.emAberto);
    expect(e.titulo, 'R\$ 400,00');
    expect(e.linha, 'Vence em 05/12 · +1 em aberto');
    expect(e.subtituloTopo, '2 em aberto');
    expect(e.paraPagar!.id, 2);
  });

  test('atrasada: em vermelho, paga a mais antiga', () {
    final e = financeiroAlunoEstado([
      _m(1, '2026-11', 'ATRASADO', venc: '2026-11-05'),
      _m(2, '2026-12', 'PENDENTE', venc: '2026-12-05'),
    ], parcial: false);
    expect(e.situacao, FinanceiroAlunoSituacao.atrasado);
    expect(e.titulo, 'R\$ 200,00 em atraso');
    expect(e.linha, 'Venceu em 05/11 · +1 em aberto');
    expect(e.subtituloTopo, '1 em atraso');
    expect(e.paraPagar!.id, 1);
  });

  test('lista recortada avisa que soma só as carregadas', () {
    final e = financeiroAlunoEstado([
      _m(1, '2026-12', 'PENDENTE', venc: '2026-12-05'),
    ], parcial: true);
    expect(e.linha, endsWith('nas cobranças carregadas'));
  });

  test('pagamento automático: forma e status curto', () {
    expect(recorrenciaFormaLabel('PIX'), 'PIX todo mês');
    expect(recorrenciaFormaLabel('CARTAO'), 'Cartão (Mercado Pago)');
    expect(recorrenciaFormaLabel(null), isNull);
    expect(recorrenciaAlunoStatusCurto(status: 'ATIVA'), 'Ativo');
    expect(recorrenciaAlunoStatusCurto(status: 'PAUSADA'), 'Pausado');
    expect(
      recorrenciaAlunoStatusLabel(status: 'PENDENTE', initPoint: 'https://mp'),
      'Aguardando sua autorização',
    );
  });
}
