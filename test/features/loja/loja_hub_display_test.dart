import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/loja/utils/loja_hub_display.dart';

void main() {
  test('lojaHubViewLabel e contagem', () {
    expect(lojaHubViewLabel(LojaHubView.vitrine), 'Vitrine');
    expect(lojaHubViewLabel(LojaHubView.pedidos), 'Pedidos');
    expect(
      lojaCountLabel(view: LojaHubView.vitrine, count: 0),
      'Nenhum pacote',
    );
    expect(
      lojaCountLabel(view: LojaHubView.vitrine, count: 1),
      '1 pacote',
    );
    expect(
      lojaCountLabel(view: LojaHubView.pedidos, count: 2),
      '2 pedidos',
    );
  });

  test('busca de vitrine e pedidos', () {
    expect(
      lojaPacoteMatches(titulo: 'Anual', descricao: '12 meses', query: 'anual'),
      isTrue,
    );
    expect(
      lojaPacoteMatches(titulo: 'Anual', descricao: '12 meses', query: 'pix'),
      isFalse,
    );
    expect(
      lojaPedidoMatches(
        buyerNome: 'Ana',
        buyerEmail: 'ana@ex.com',
        status: 'PENDENTE',
        query: 'pendente',
      ),
      isTrue,
    );
  });

  test('lojaPacoteSubtitle prefere descricao', () {
    expect(
      lojaPacoteSubtitle(descricao: 'Consultoria mensal', duracaoMeses: 3),
      'Consultoria mensal',
    );
    expect(lojaPacoteSubtitle(descricao: '  ', duracaoMeses: 1), '1 mês');
    expect(lojaPacoteSubtitle(duracaoMeses: 3), '3 meses');
  });

  test('lojaPedido labels não expõem id', () {
    expect(
      lojaPedidoLabel(buyerNome: 'Ana', buyerEmail: 'ana@ex.com'),
      'Ana',
    );
    expect(
      lojaPedidoLabel(buyerNome: '  ', buyerEmail: 'ana@ex.com'),
      'ana@ex.com',
    );
    expect(lojaPedidoLabel(buyerEmail: ''), 'Comprador');
    expect(lojaPedidoStatusLabel('PAGO'), 'Pago');
    expect(lojaPedidoStatusLabel('pendente'), 'Pendente');
    expect(lojaPedidoStatusLabel(''), 'Sem status');
    expect(
      lojaPedidoSubtitle(
        buyerNome: 'Ana',
        buyerEmail: 'ana@ex.com',
        status: 'PENDENTE',
      ),
      'Pendente · ana@ex.com',
    );
    expect(lojaPedidoFxIcon('PAGO'), 'circle-check');
    expect(lojaPedidoFxIcon('PENDENTE'), 'pix');
    expect(lojaPedidoPendente('PENDENTE'), isTrue);
    expect(lojaPedidoPendente('PAGO'), isFalse);
    expect(lojaPedidoPix('  abc  '), 'abc');
    expect(lojaPedidoPix('  '), isNull);
  });
}
