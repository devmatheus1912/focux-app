import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';

/// Escala tipográfica: oito papéis, três pesos. Nenhum `fontSize` literal
/// fora do kit; PDF (escala de papel) e telas de QA ficam de fora.
void main() {
  const kit = {
    'lib/core/theme/tokens_strip.dart',
    'lib/core/theme/focux_hub_typography.dart',
    'lib/core/theme/focux_typography.dart',
    'lib/core/theme/app_theme.dart',
  };
  const fora = ['lib/core/pdf/', 'lib/features/qa/'];

  /// Exceções nomeadas, com motivo.
  const excecoes = {
    // Emoji de reação: é ícone, não texto.
    'lib/features/chat/screens/conversation_screen_sheets_actions.part.dart',
  };

  Iterable<(String, String)> fontes() sync* {
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final p = f.path.replaceAll('\\', '/');
      yield (p, f.readAsStringSync());
    }
  }

  bool usaPdf(String fonte) => fonte.contains("package:pdf/");

  test('nenhum fontSize literal fora do kit', () {
    final literal = RegExp(r'fontSize:\s*\d');
    final ruins = <String>[
      for (final (p, fonte) in fontes())
        if (!kit.contains(p) &&
            !fora.any(p.startsWith) &&
            !excecoes.contains(p) &&
            !usaPdf(fonte) &&
            literal.hasMatch(fonte))
          p,
    ];
    expect(ruins, isEmpty, reason: 'use os papéis de FocuxHubTypography/TokensStrip');
  });

  test('três pesos: sem w800, w900 nem bold fora do PDF', () {
    final pesado = RegExp(r'\bFontWeight\.(w800|w900|bold)\b');
    final ruins = <String>[
      for (final (p, fonte) in fontes())
        if (!p.startsWith('lib/core/pdf/') && !usaPdf(fonte) && pesado.hasMatch(fonte)) p,
    ];
    expect(ruins, isEmpty);
  });

  test('tamanhos do kit pertencem à escala', () {
    expect(
      TokensStrip.escala.toSet(),
      {11.0, 12.0, 13.0, 15.0, 17.0, 22.0, 32.0, 40.0},
    );
  });
}
