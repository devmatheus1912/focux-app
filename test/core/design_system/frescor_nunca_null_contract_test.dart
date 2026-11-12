import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `FxHubFreshness.fromFetchedAt` devolve `null` nos primeiros 5 min. Montar
/// texto com ele direto escreve "null" na tela (aconteceu nas Trilhas, 229).
/// Use `FxHubFreshness.joinCount` ou `??`.
void main() {
  test('frescor nunca entra cru em texto nem em join', () {
    final proibido = [
      RegExp(r"\$\{?(freshness|freshnessLabel)\b"),
      RegExp(r"\[[^\]]*\b(freshness|freshnessLabel)\b[^\]]*\]\.join"),
    ];
    final achados = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final p = f.path.replaceAll(r'\', '/');
      if (p.endsWith('core/ux/fx_hub_freshness.dart')) continue;
      final linhas = f.readAsLinesSync();
      for (var i = 0; i < linhas.length; i++) {
        final l = linhas[i];
        // `if (freshness != null) freshness` dentro da lista já protege.
        if (RegExp(r'(freshness|freshnessLabel) != null').hasMatch(l)) continue;
        if (proibido.any((r) => r.hasMatch(l))) {
          achados.add('$p:${i + 1}');
        }
      }
    }
    expect(achados, isEmpty, reason: 'Use FxHubFreshness.joinCount: $achados');
  });
}
