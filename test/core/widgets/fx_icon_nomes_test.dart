import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nome de ícone que o FxIcon não conhece cai num círculo vazio (foi o que
/// apareceu em "Cobrança automática"). Todo nome usado precisa ter desenho.
void main() {
  test('todo nome de FxIcon usado no app tem desenho', () {
    final icone = File('lib/core/widgets/fx_icon.dart').readAsStringSync();
    final desenhados = RegExp(
      r"case '([\w-]+)':",
    ).allMatches(icone).map((m) => m.group(1)!).toSet();
    final usados = <String, String>{};
    for (final arquivo in Directory('lib').listSync(recursive: true)) {
      if (arquivo is! File || !arquivo.path.endsWith('.dart')) continue;
      if (arquivo.path.contains('l10n')) continue;
      final texto = arquivo.readAsStringSync();
      for (final rx in [
        RegExp(r"fxIcon:\s*'([\w-]+)'"),
        RegExp(r"FxIcon\(\s*name:\s*'([\w-]+)'"),
      ]) {
        for (final m in rx.allMatches(texto)) {
          usados.putIfAbsent(m.group(1)!, () => arquivo.path);
        }
      }
    }
    final faltando = {
      for (final e in usados.entries)
        if (!desenhados.contains(e.key)) e.key: e.value,
    };
    expect(faltando, isEmpty, reason: 'sem desenho no FxIcon: $faltando');
  });
}
