import 'package:flutter/services.dart';

import 'fx_money.dart';

/// Campo de dinheiro como app de banco: quem digita só escolhe números e o
/// valor se monta da direita para a esquerda ("1", "17", "1,75", "17,55"…),
/// sempre em `R$ 1.234,56`. Não há vírgula nem ponto para errar: o teclado
/// pt-BR do iPhone tem vírgula e o filtro antigo a descartava, gravando
/// R$ 17.550,00 no lugar de R$ 175,50.
class FxMoneyInputFormatter extends TextInputFormatter {
  const FxMoneyInputFormatter();

  /// R$ 99.999.999,99: o backend recusa acima de R$ 100.000 de qualquer forma.
  static const maxDigitos = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    digitos = digitos.replaceFirst(RegExp(r'^0+'), '');
    if (digitos.length > maxDigitos) return oldValue;
    if (digitos.isEmpty) return TextEditingValue.empty;
    final texto = formatBrlCents(int.parse(digitos));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Texto inicial do campo para um valor existente ("R$ 175,50"); vazio se zero.
String fxMoneyCampoTexto(FxMoney? valor) =>
    valor == null || valor.isZero ? '' : formatBrlCents(valor.cents);

/// Valor do campo; nulo se vazio ou inválido.
FxMoney? fxMoneyDoCampo(String? texto) {
  if (texto == null || texto.trim().isEmpty) return null;
  try {
    return FxMoney.fromInput(texto);
  } on FormatException {
    return null;
  }
}

/// Validador padrão: obrigatório e maior que zero.
String? fxMoneyValidar(String? texto) {
  final v = fxMoneyDoCampo(texto);
  if (texto == null || texto.trim().isEmpty) return 'Informe o valor';
  if (v == null || !v.isPositive) return 'Valor inválido';
  return null;
}
