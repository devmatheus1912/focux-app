import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migração sem "aluno(s)" (plural de verdade)', () {
    final achados = <String>[];
    for (final f in Directory('lib/features/growth').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.readAsStringSync().contains('aluno(s)')) achados.add(f.path);
    }
    final arb = File('lib/l10n/app_pt.arb').readAsStringSync();
    expect(achados, isEmpty);
    expect(arb, isNot(contains('aluno(s)')));
  });
}
