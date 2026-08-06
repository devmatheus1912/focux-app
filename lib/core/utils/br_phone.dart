import 'package:flutter/services.dart';

/// Telefone BR (10–11 dígitos) — máscara, normalização e validação.
abstract final class BrPhone {
  static final RegExp _digitsOnly = RegExp(r'\D');

  static String digitsOnly(String value) => value.replaceAll(_digitsOnly, '');

  /// Dígitos para API; null se vazio.
  static String? normalizeOrNull(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) return null;
    return digits;
  }

  /// null = ok (vazio permitido); senão mensagem de erro.
  static String? validateOptional(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) return null;
    if (digits.length < 10 || digits.length > 11) {
      return 'Informe um telefone válido com DDD.';
    }
    return null;
  }

  /// Formata dígitos da API para máscara de UI.
  static String formatDisplay(String? raw) {
    final digits = digitsOnly(raw ?? '');
    if (digits.isEmpty) return '';
    return formatter()
        .formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: digits),
        )
        .text;
  }

  static TextInputFormatter formatter() => const BrPhoneInputFormatter();
}

class BrPhoneInputFormatter extends TextInputFormatter {
  const BrPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (digits.length > 10 && i == 7) {
        buffer.write('-');
      } else if (digits.length <= 10 && i == 6) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
