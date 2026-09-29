import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
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

/// Fundos mais claros (pior caso) sobre os quais o campo aparece.
const _fundosClaros = [EagleTokens.paper, EagleTokens.card];
const _fundosEscuros = [
  EagleTokens.darkCardHi,
  EagleTokens.darkCard,
  TokensStrip.cinematicSurface,
  EagleTokens.darkBg,
];

Future<(InputDecoration, InputDecoration)> _decos(
  WidgetTester tester,
  Brightness brilho,
) async {
  late InputDecoration inset;
  late InputDecoration flutuante;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brilho),
      home: Builder(
        builder: (context) {
          inset = FxInputDeco.insetGrouped(context, hint: 'Nome completo');
          flutuante = FxInputDeco.build(context, 'E-mail', hint: 'você@x.com');
          return const SizedBox();
        },
      ),
    ),
  );
  return (inset, flutuante);
}

void main() {
  test('luminância WCAG confere com os extremos', () {
    expect(_contraste(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(_contraste(Colors.white, Colors.white), closeTo(1, 0.01));
  });

  for (final (brilho, fundos) in [
    (Brightness.light, _fundosClaros),
    (Brightness.dark, _fundosEscuros),
  ]) {
    testWidgets('placeholder e rótulo ≥ 4,5:1 no tema ${brilho.name}', (
      tester,
    ) async {
      final (inset, flutuante) = await _decos(tester, brilho);
      final placeholders = [
        inset.hintStyle!.color!,
        flutuante.hintStyle!.color!,
      ];
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
          _contraste(flutuante.labelStyle!.color!, campo),
          greaterThanOrEqualTo(4.5),
          reason: 'rótulo sobre o campo em $fundo',
        );
        expect(
          _contraste(flutuante.hintStyle!.color!, campo),
          greaterThanOrEqualTo(4.5),
          reason: 'placeholder sobre o campo em $fundo',
        );
      }
    });
  }
}
