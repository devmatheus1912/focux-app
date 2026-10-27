@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/perfil/widgets/identidade_paletas_grade.dart';
import 'package:focux_app/features/perfil/widgets/identidade_previa_app.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

Widget _app(Widget child, {bool dark = false}) => MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: EagleTokens.brandAccent,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    useMaterial3: true,
  ),
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(
    backgroundColor: dark ? const Color(0xFF14161A) : const Color(0xFFF6F4FA),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  final midnight = CuratedBrandPalette.premium.firstWhere(
    (p) => p.id == 'midnight_gold',
  );

  for (final estilo in BrandStyle.values) {
    testWidgets('prévia do app: ${estilo.name} (claro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          IdentidadePreviaApp(
            palette: midnight,
            estilo: estilo,
            escuro: false,
            nomePersonal: 'Matheus Teste',
            slogan: 'Transformando vidas através do movimento',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectFocuxGolden(
        find.byType(MaterialApp),
        'goldens/identidade_previa_${estilo.name}_390.png',
      );
    });
  }

  testWidgets('prévia do app: cinematográfico (escuro)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        dark: true,
        IdentidadePreviaApp(
          palette: midnight,
          estilo: BrandStyle.cinematografico,
          escuro: true,
          nomePersonal: 'Matheus Teste',
          slogan: 'Transformando vidas através do movimento',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/identidade_previa_cinematografico_390_dark.png',
    );
  });

  testWidgets('grade de paletas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(IdentidadePaletasGrade(selecionada: midnight, onSelect: (_) {})),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/identidade_paletas_grade_390.png',
    );
  });
}
