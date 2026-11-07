import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/core/money/fx_money_input.dart';

/// Digita tecla por tecla, como o teclado faz.
String digitar(String teclas) {
  const f = FxMoneyInputFormatter();
  var v = TextEditingValue.empty;
  for (final c in teclas.split('')) {
    final texto = v.text + c;
    v = f.formatEditUpdate(
      v,
      TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length)),
    );
  }
  return v.text;
}

void main() {
  test('175,50 com o teclado pt-BR (vírgula) vira R\$ 175,50, não R\$ 17.550', () {
    // O bug: o filtro antigo descartava a vírgula e gravava 17550.
    expect(digitar('17550'), 'R\$ 175,50');
    expect(digitar('175,50'), 'R\$ 175,50');
    expect(fxMoneyDoCampo(digitar('175,50')), const FxMoney.cents(17550));
  });

  test('milhar e zeros à esquerda', () {
    expect(digitar('120000'), 'R\$ 1.200,00');
    expect(digitar('005'), 'R\$ 0,05');
  });

  test('colar "R\$ 1.234,56" mantém o valor', () {
    const f = FxMoneyInputFormatter();
    final v = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'R\$ 1.234,56'),
    );
    expect(v.text, 'R\$ 1.234,56');
    expect(fxMoneyDoCampo(v.text), const FxMoney.cents(123456));
  });

  test('apagar tudo deixa vazio e o validador pede o valor', () {
    const f = FxMoneyInputFormatter();
    final v = f.formatEditUpdate(
      const TextEditingValue(text: 'R\$ 0,05'),
      const TextEditingValue(text: 'R\$ 0,0'),
    );
    expect(fxMoneyValidar(f.formatEditUpdate(v, const TextEditingValue(text: '')).text), 'Informe o valor');
    expect(fxMoneyValidar('R\$ 0,00'), 'Valor inválido');
    expect(fxMoneyValidar('R\$ 10,00'), isNull);
  });

  test('texto inicial de um valor existente', () {
    expect(fxMoneyCampoTexto(const FxMoney.cents(25000)), 'R\$ 250,00');
    expect(fxMoneyCampoTexto(FxMoney.zero), '');
  });
}
