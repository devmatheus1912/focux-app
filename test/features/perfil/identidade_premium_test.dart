import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/perfil/utils/identidade_visual_display.dart';
import 'package:focux_app/features/perfil/widgets/identidade_capa_tile.dart';
import 'package:focux_app/features/perfil/widgets/identidade_paletas_grade.dart';
import 'package:focux_app/features/perfil/widgets/identidade_previa_app.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

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
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('textos e estado da tela', () {
    test('cada estilo tem nome e descrição próprios', () {
      final nomes = {
        for (final e in BrandStyle.values) identidadeEstiloLabel(e),
      };
      final descricoes = {
        for (final e in BrandStyle.values) identidadeEstiloDescricao(e),
      };
      expect(nomes, hasLength(3));
      expect(descricoes, hasLength(3));
      expect(
        identidadeEstiloLabel(BrandStyle.cinematografico),
        'Cinematográfico',
      );
    });

    test('mudar estilo ou capa suja o formulário', () {
      bool sujo({BrandStyle estilo = BrandStyle.classico, String? capa}) =>
          identidadeIsDirty(
            perfilLoaded: true,
            slogan: 'a',
            baselineSlogan: 'a',
            logoUrl: null,
            baselineLogo: null,
            palette: CuratedBrandPalette.focuxDefault,
            baselinePalette: CuratedBrandPalette.focuxDefault,
            estilo: estilo,
            baselineEstilo: BrandStyle.classico,
            capaUrl: capa,
            baselineCapa: null,
          );
      expect(sujo(), isFalse);
      expect(sujo(estilo: BrandStyle.minimalista), isTrue);
      expect(sujo(capa: 'https://cdn.test/capa.jpg'), isTrue);
    });

    test('aviso de contraste é opcional e nunca vazio', () {
      for (final p in CuratedBrandPalette.premium) {
        final aviso = identidadeAvisoContraste(p);
        if (aviso != null) expect(aviso.trim(), isNotEmpty, reason: p.name);
      }
    });
  });

  group('prévia do app', () {
    for (final estilo in BrandStyle.values) {
      for (final escuro in [false, true]) {
        testWidgets('${estilo.name} ${escuro ? 'escuro' : 'claro'}', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(1170, 3000);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _app(
              dark: escuro,
              IdentidadePreviaApp(
                palette: CuratedBrandPalette.premium[1],
                estilo: estilo,
                escuro: escuro,
                nomePersonal: 'Matheus Teste',
                slogan: 'Transformando vidas através do movimento',
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          // os mesmos widgets da Home: assinatura, cartão do personal e dock
          expect(find.text('Treino com Matheus Teste'), findsOneWidget);
          expect(find.text('Seu personal'), findsOneWidget);
          expect(find.text('Conversar'), findsOneWidget);
          expect(find.text('Seu personal'), findsWidgets);
        });
      }
    }

    testWidgets('a prévia não recebe toque nem foco', (tester) async {
      var tocou = false;
      await tester.pumpWidget(
        _app(
          IdentidadePreviaApp(
            palette: CuratedBrandPalette.premium[0],
            estilo: BrandStyle.classico,
            escuro: false,
            nomePersonal: 'Ana',
          ),
        ),
      );
      await tester.tap(find.text('Conversar'), warnIfMissed: false);
      expect(tocou, isFalse);
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('capa aparece só quando existe', (tester) async {
      await tester.pumpWidget(
        _app(
          IdentidadePreviaApp(
            palette: CuratedBrandPalette.premium[0],
            estilo: BrandStyle.cinematografico,
            escuro: false,
            nomePersonal: 'Ana',
            capaUrl: 'https://cdn.test/capa.jpg',
          ),
        ),
      );
      await tester.pump();
      expect(
        find.bySemanticsLabel('Capa do seu personal'),
        findsNothing,
      ); // excludeSemantics na prévia
    });
  });

  group('grade de paletas', () {
    testWidgets('mostra todas, marca a escolhida e responde ao toque', (
      tester,
    ) async {
      CuratedBrandPalette? escolhida;
      tester.view.physicalSize = const Size(1170, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          IdentidadePaletasGrade(
            selecionada: CuratedBrandPalette.premium[0],
            onSelect: (p) => escolhida = p,
          ),
        ),
      );
      expect(CuratedBrandPalette.premium.length, greaterThanOrEqualTo(8));
      for (final p in CuratedBrandPalette.premium) {
        expect(find.text(p.name), findsOneWidget, reason: p.name);
      }
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.tap(find.text('Midnight Gold'));
      expect(escolhida?.id, 'midnight_gold');
    });

    testWidgets('sem onSelect (sem white-label) não responde', (tester) async {
      tester.view.physicalSize = const Size(1170, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          IdentidadePaletasGrade(selecionada: CuratedBrandPalette.premium[0]),
        ),
      );
      await tester.tap(find.text('Midnight Gold'));
      expect(tester.takeException(), isNull);
    });
  });

  group('capa', () {
    testWidgets('sem capa: convite e "Adicionar capa"', (tester) async {
      var abriu = 0;
      await tester.pumpWidget(
        _app(
          IdentidadeCapaTile(
            url: null,
            uploading: false,
            onEscolher: () => abriu++,
            onRemover: () {},
          ),
        ),
      );
      expect(find.text('Adicionar capa'), findsOneWidget);
      expect(find.text('Remover capa'), findsNothing);
      await tester.tap(find.text('Adicionar capa'));
      expect(abriu, 1);
    });

    testWidgets('com capa: troca e remove', (tester) async {
      var removeu = 0;
      await tester.pumpWidget(
        _app(
          IdentidadeCapaTile(
            url: 'https://cdn.test/capa.jpg',
            uploading: false,
            onEscolher: () {},
            onRemover: () => removeu++,
          ),
        ),
      );
      expect(find.text('Trocar capa'), findsOneWidget);
      await tester.tap(find.text('Remover capa'));
      expect(removeu, 1);
    });

    testWidgets('enviando bloqueia o botão', (tester) async {
      var abriu = 0;
      await tester.pumpWidget(
        _app(
          IdentidadeCapaTile(
            url: null,
            uploading: true,
            onEscolher: () => abriu++,
            onRemover: null,
          ),
        ),
      );
      await tester.tap(find.text('Adicionar capa'), warnIfMissed: false);
      expect(abriu, 0);
    });
  });
}
