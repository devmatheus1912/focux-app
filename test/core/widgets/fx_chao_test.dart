import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/core/theme/brand_tint.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_chao.dart';

Color _corPintada(WidgetTester tester) =>
    tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byType(FxChao),
            matching: find.byType(ColoredBox),
          ),
        )
        .color;

Future<void> _pump(
  WidgetTester tester, {
  required Brightness brilho,
  bool forceDark = false,
  BrandStyle? estilo,
}) async {
  Widget home = FxChao(
    forceDark: forceDark,
    child: const Center(child: Text('conteudo')),
  );
  if (estilo != null) {
    home = BrandTint(
      estilo: estilo,
      primaria: const Color(0xFF8B1E3F),
      secundaria: const Color(0xFFF2B134),
      child: home,
    );
  }
  await tester.pumpWidget(
    MaterialApp(theme: ThemeData(brightness: brilho), home: home),
  );
}

void main() {
  testWidgets('claro pinta o paper sólido do guia', (tester) async {
    await _pump(tester, brilho: Brightness.light);
    expect(find.text('conteudo'), findsOneWidget);
    expect(_corPintada(tester), TokensStrip.paper);
    expect(TokensStrip.paper, const Color(0xFFF4F6F8));
  });

  testWidgets('escuro pinta o chão petróleo sólido', (tester) async {
    await _pump(tester, brilho: Brightness.dark);
    expect(_corPintada(tester), TokensStrip.cinematicBg);
  });

  testWidgets('forceDark ignora o tema claro (entrada e splash)', (
    tester,
  ) async {
    await _pump(tester, brilho: Brightness.light, forceDark: true);
    expect(_corPintada(tester), TokensStrip.cinematicBg);
  });

  testWidgets('sem degradê nem brilho: só uma cor', (tester) async {
    await _pump(tester, brilho: Brightness.light);
    final caixas = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(FxChao),
        matching: find.byType(Container),
      ),
    );
    for (final c in caixas) {
      final deco = c.decoration;
      expect(deco is BoxDecoration && deco.gradient != null, isFalse);
    }
  });

  testWidgets('só o estilo Cinematográfico tinge o chão, ainda sólido', (
    tester,
  ) async {
    await _pump(tester, brilho: Brightness.light, estilo: BrandStyle.classico);
    expect(_corPintada(tester), TokensStrip.paper);

    await _pump(
      tester,
      brilho: Brightness.light,
      estilo: BrandStyle.cinematografico,
    );
    final tinto = _corPintada(tester);
    expect(tinto, isNot(TokensStrip.paper));
    expect(tinto.a, 1.0);
  });
}
