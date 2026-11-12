import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/loja/models/loja_pedido.dart';
import 'package:focux_app/features/pacotes/screens/vendas_screen.dart';
import 'package:focux_app/features/pacotes/utils/pacote_display.dart';

void main() {
  test('duração e o que inclui numa linha', () {
    expect(pacoteDuracaoLabel(1), '1 mês');
    expect(pacoteDuracaoLabel(12), '12 meses');
    expect(
      pacoteLinha(treino: true, consultoria: true, meses: 1),
      '1 mês · Treino e consultoria',
    );
    expect(
      pacoteLinha(treino: false, consultoria: true, meses: 3),
      '3 meses · Consultoria',
    );
    expect(pacoteLinha(treino: false, consultoria: false, meses: 6), '6 meses');
  });

  test('subtítulo de Vendas diz o que pede ação', () {
    expect(vendasSubtitulo(pixAguardando: 1, planos: 4), '1 PIX aguardando');
    expect(vendasSubtitulo(pixAguardando: 0, planos: 2), '2 planos à venda');
    expect(
      vendasSubtitulo(pixAguardando: 0, planos: 0),
      'Nenhum plano à venda',
    );
  });

  test('estado do pedido', () {
    LojaPedido pedido(String status, {int? alunoId}) => LojaPedido.fromJson({
      'id': 1,
      'buyerEmail': 'a@b.c',
      'valor': '200.00',
      'status': status,
      'alunoId': alunoId,
    });
    expect(vendasPedidoEstado(pedido('PENDENTE')), 'Aguardando PIX');
    expect(
      vendasPedidoEstado(pedido('PAGO', alunoId: 3)),
      'Pago · aluno criado',
    );
  });
}
