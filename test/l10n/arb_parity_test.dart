import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _messageKeys(String locale) {
  final raw = File('lib/l10n/app_$locale.arb').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

/// O app sobe só em PT-BR: en/es ficam congelados e caem no PT (template)
/// onde não têm tradução. Não podem ter chave que o PT já não tem.
void main() {
  final pt = _messageKeys('pt');

  for (final locale in ['en', 'es']) {
    test('app_$locale.arb não tem chave fora do pt', () {
      expect(_messageKeys(locale).difference(pt), isEmpty);
    });
  }

  test('app travado em PT', () {
    final mainDart = File('lib/main.dart').readAsStringSync();
    expect(mainDart, contains("locale: const Locale('pt')"));
  });
}
