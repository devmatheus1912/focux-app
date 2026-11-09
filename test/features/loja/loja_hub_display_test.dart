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


  test('lojaPacoteSubtitle prefere descricao', () {
    expect(
      lojaPacoteSubtitle(descricao: 'Consultoria mensal', duracaoMeses: 3),
      'Consultoria mensal',
    );
    expect(lojaPacoteSubtitle(descricao: '  ', duracaoMeses: 1), '1 mês');
    expect(lojaPacoteSubtitle(duracaoMeses: 3), '3 meses');
  });

}
