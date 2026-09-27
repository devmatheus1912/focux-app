import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _messageKeys(String locale) {
  final raw = File('lib/l10n/app_$locale.arb').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  final pt = _messageKeys('pt');

  for (final locale in ['en', 'es']) {
    test('app_$locale.arb tem todas as chaves do pt', () {
      expect(pt.difference(_messageKeys(locale)), isEmpty);
    });
  }
}
