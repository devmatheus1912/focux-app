import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/widgets/fx_strip_card.dart';

double _contraste(Color a, Color b) {
  final (claro, escuro) =
      a.computeLuminance() > b.computeLuminance()
          ? (a.computeLuminance(), b.computeLuminance())
          : (b.computeLuminance(), a.computeLuminance());
  return (claro + 0.05) / (escuro + 0.05);
}

/// Marca clara, escura e saturada, nos dois temas.
void main() {
  const marcas = <String, Color>{
    'teal Focux': Color(0xFF0D9488),
    'amarelo claro': Color(0xFFFDE047),
    'branco': Color(0xFFFFFFFF),
    'preto': Color(0xFF000000),
    'vermelho saturado': Color(0xFFFF0000),
    'azul saturado': Color(0xFF0000FF),
    'rosa': Color(0xFFEC4899),
  };

  for (final MapEntry(key: nome, value: marca) in marcas.entries) {
    for (final dark in [false, true]) {
      testWidgets('$nome, ${dark ? 'escuro' : 'claro'}: texto legível', (
        tester,
      ) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        );
        final cor = BrandPalette.cardDeMarca(marca, dark: dark);
        final sobre = fxPaletaSobreMarca(ctx, accent: marca);
        for (final fundo in [cor.fundo, cor.fundoFim]) {
          expect(_contraste(sobre.ink, fundo), greaterThanOrEqualTo(4.5));
          expect(_contraste(sobre.mute, fundo), greaterThanOrEqualTo(4.5));
        }
      });
    }
  }
}
