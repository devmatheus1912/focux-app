import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/money/fx_money.dart';

void main() {
  test('parse arredonda para centavos sem somar em double', () {
    expect(FxMoney.parse(199.9).cents, 19990);
    expect(FxMoney.parse('1.200,50').cents, 120050);
    expect(FxMoney.parse('199,90').cents, 19990);
    expect(FxMoney.parse(null).isZero, isTrue);
    expect((FxMoney.parse(1500) - FxMoney.parse(1200)).cents, 30000);
    expect(FxMoney.parse(1200).wire, '1200.00');
    expect(FxMoney.parse(199.9).format(showDecimals: true), 'R\$ 199,90');
    expect(FxMoney.parse(19.99).cents, 1999);
    expect(FxMoney.parse('120.50').cents, 12050);
    expect(FxMoney.reais('99.90'), 99.9);
    expect(FxMoney.reais(150), 150);
  });

  test('formatCobranca sempre mostra centavos, sem truncar', () {
    expect(FxMoney.parse(149.9).formatCobranca(), 'R\$ 149,90');
    expect(FxMoney.parse(1000).formatCobranca(), 'R\$ 1.000,00');
    expect(FxMoney.parse(0.5).formatCobranca(), 'R\$ 0,50');
    expect(FxMoney.parse('-12,34').formatCobranca(), '-R\$ 12,34');
  });

  test('fromInput rejeita vazio', () {
    expect(() => FxMoney.fromInput(''), throwsFormatException);
  });
}
