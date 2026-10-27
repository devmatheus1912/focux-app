import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/core/theme/brand_tint.dart';
import 'package:focux_app/core/widgets/cinematic_mesh_background.dart';
import 'package:focux_app/core/widgets/fx_dock.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_capa_banner.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Widget _app(Widget child, {BrandStyle? estilo, bool dark = false}) {
  final base = MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A2332),
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
    ),
    locale: const Locale('pt'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: S.localizationsDelegates,
    home: Scaffold(body: child),
  );
  if (estilo == null) return base;
  return BrandTint(
    estilo: estilo,
    primaria: const Color(0xFF1A2332),
    secundaria: const Color(0xFFC9A962),
    child: base,
  );
}

void main() {
  testWidgets('capa sem imagem não ocupa espaço', (tester) async {
    await tester.pumpWidget(_app(const AlunoCapaBanner(url: null)));
    expect(tester.getSize(find.byType(AlunoCapaBanner)).height, 0);
    await tester.pumpWidget(_app(const AlunoCapaBanner(url: '  ')));
    expect(tester.getSize(find.byType(AlunoCapaBanner)).height, 0);
  });

  testWidgets('capa com imagem ocupa a altura combinada e tem rótulo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const AlunoCapaBanner(url: 'https://cdn.test/capa.jpg', altura: 150),
      ),
    );
    expect(tester.getSize(find.byType(AlunoCapaBanner)).height, 150);
    expect(find.bySemanticsLabel('Capa do seu personal'), findsOneWidget);
    handle.dispose();
  });

  test('BrandTint avisa quando o estilo muda', () {
    const a = BrandTint(
      estilo: BrandStyle.classico,
      primaria: Color(0xFF000000),
      secundaria: Color(0xFFFFFFFF),
      child: SizedBox(),
    );
    const b = BrandTint(
      estilo: BrandStyle.cinematografico,
      primaria: Color(0xFF000000),
      secundaria: Color(0xFFFFFFFF),
      child: SizedBox(),
    );
    expect(b.updateShouldNotify(a), isTrue);
    expect(a.updateShouldNotify(a), isFalse);
  });

  testWidgets('fundo animado aceita os três estilos sem erro', (tester) async {
    for (final e in [null, ...BrandStyle.values]) {
      for (final escuro in [false, true]) {
        await tester.pumpWidget(
          _app(
            dark: escuro,
            estilo: e,
            const CinematicMeshBackground(child: SizedBox.expand()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: '$e escuro=$escuro');
      }
    }
  });

  testWidgets('dock renderiza em todos os estilos (acento checado)', (
    tester,
  ) async {
    for (final e in [null, ...BrandStyle.values]) {
      await tester.pumpWidget(
        _app(
          estilo: e,
          Align(
            alignment: Alignment.bottomCenter,
            child: Builder(
              builder:
                  (context) => FxDock(
                    items: FxDockItems.aluno(S.of(context)),
                    currentIndex: 0,
                    onTap: (_) {},
                    isDark: false,
                  ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '$e');
      expect(find.text('Hoje'), findsOneWidget);
    }
  });
}
