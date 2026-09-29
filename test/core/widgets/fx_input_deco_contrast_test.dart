import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/theme/shell_chrome.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

double _canal(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminancia(Color c) =>
    0.2126 * _canal(c.r) + 0.7152 * _canal(c.g) + 0.0722 * _canal(c.b);

double _contraste(Color frente, Color fundo) {
  final opaca = Color.alphaBlend(frente, fundo);
  final a = _luminancia(opaca);
  final b = _luminancia(fundo);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// Fundos (pior caso) sobre os quais o campo aparece, incluindo o glass do
/// card e o fill do sheet compostos sobre a página.
List<Color> _fundos({required bool dark, required Color sheetFill}) {
  final pagina = dark ? EagleTokens.darkBg : EagleTokens.paper;
  final glass = Color.alphaBlend(
    TokensStrip.glassFill(dark: dark, opacity: 0.94),
    pagina,
  );
  final sheet = Color.alphaBlend(sheetFill, pagina);
  return dark
      ? [
        EagleTokens.darkCardHi,
        EagleTokens.darkCard,
        TokensStrip.cinematicSurface,
        pagina,
        glass,
        sheet,
      ]
      : [pagina, EagleTokens.card, glass, sheet];
}

typedef _Cenario =
    ({InputDecoration inset, InputDecoration flutuante, List<Color> fundos});

Future<_Cenario> _cenario(WidgetTester tester, Brightness brilho) async {
  late _Cenario cenario;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brilho),
      home: Builder(
        builder: (context) {
          final dark = brilho == Brightness.dark;
          cenario = (
            inset: FxInputDeco.insetGrouped(context, hint: 'Nome completo'),
            flutuante: FxInputDeco.build(context, 'E-mail', hint: 'você@x.com'),
            fundos: _fundos(
              dark: dark,
              sheetFill: ShellChrome.forBrightness(context, dark).sheetFill,
            ),
          );
          return const SizedBox();
        },
      ),
    ),
  );
  return cenario;
}

void main() {
  test('luminância WCAG confere com os extremos', () {
    expect(_contraste(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(_contraste(Colors.white, Colors.white), closeTo(1, 0.01));
  });

  for (final brilho in Brightness.values) {
    testWidgets('placeholder e rótulo ≥ 4,5:1 no tema ${brilho.name}', (
      tester,
    ) async {
      final (:inset, :flutuante, :fundos) = await _cenario(tester, brilho);
      final placeholders = [
        inset.hintStyle!.color!,
        flutuante.hintStyle!.color!,
      ];
      final rotulo = flutuante.labelStyle!.color!;
      for (final fundo in fundos) {
        for (final cor in placeholders) {
          expect(
            _contraste(cor, fundo),
            greaterThanOrEqualTo(4.5),
            reason: 'placeholder $cor sobre $fundo',
          );
        }
        final campo = Color.alphaBlend(flutuante.fillColor!, fundo);
        expect(
          _contraste(rotulo, campo),
          greaterThanOrEqualTo(4.5),
          reason: 'rótulo sobre o campo em $fundo',
        );
        expect(
          _contraste(rotulo, campo),
          greaterThanOrEqualTo(_contraste(flutuante.hintStyle!.color!, campo)),
          reason: 'rótulo não pode ficar mais apagado que o placeholder',
        );
      }
    });
  }
}
