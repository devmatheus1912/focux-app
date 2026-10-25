import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_choice_chip.dart';
import 'package:focux_app/features/alunos/screens/add_aluno_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _abrir(WidgetTester tester, {double largura = 390, double textScale = 1}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(Size(largura, 1500));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/alunos/novo',
    routes: [
      GoRoute(path: '/alunos', builder: (_, __) => const Scaffold(body: Text('lista'))),
      GoRoute(path: '/alunos/novo', builder: (_, __) => const AddAlunoScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _digitar(WidgetTester tester, int campo, String texto) async {
  await tester.enterText(find.byType(TextFormField).at(campo), texto);
  await tester.pump();
}

void main() {
  group('campos com rótulo visível', () {
    testWidgets('rótulos e marcas de obrigatório/opcional aparecem', (tester) async {
      await _abrir(tester);

      expect(find.text('Dados do aluno'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('obrigatório'), findsNWidgets(2));
      expect(find.text('opcional'), findsOneWidget);
      expect(find.text('Com WhatsApp, o convite já sai pronto.'), findsOneWidget);
    });

    testWidgets('o rótulo continua depois de digitar', (tester) async {
      await _abrir(tester);

      await _digitar(tester, 0, 'Beatriz Andrade');

      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Beatriz Andrade'), findsOneWidget);
    });
  });

  group('sem falso progresso', () {
    testWidgets('não existe 0/2 e a linha diz o que é obrigatório', (tester) async {
      await _abrir(tester);

      expect(find.text('0/2'), findsNothing);
      expect(find.text('Só nome e e-mail são obrigatórios.'), findsOneWidget);
    });

    testWidgets('com nome e e-mail válidos vira "Pronto para convidar"', (tester) async {
      await _abrir(tester);

      await _digitar(tester, 0, 'Beatriz Andrade');
      await _digitar(tester, 1, 'bia@email.com');

      expect(find.text('Pronto para convidar Beatriz'), findsOneWidget);
      expect(find.text('Só nome e e-mail são obrigatórios.'), findsNothing);
    });
  });

  group('chips do Objetivo', () {
    testWidgets('têm o tamanho do texto, não a largura da tela', (tester) async {
      await _abrir(tester);

      final hipertrofia = find.widgetWithText(FxChoiceChip, 'Hipertrofia');
      expect(hipertrofia, findsOneWidget);
      expect(tester.getSize(hipertrofia).width, lessThan(260));
      expect(find.text('Outro'), findsWidgets);
    });

    testWidgets('selecionar e desmarcar o objetivo', (tester) async {
      await _abrir(tester);

      FxChoiceChip chip() =>
          tester.widget(find.widgetWithText(FxChoiceChip, 'Força'));
      expect(chip().selected, isFalse);
      await tester.tap(find.widgetWithText(FxChoiceChip, 'Força'));
      await tester.pump();
      expect(chip().selected, isTrue);
      await tester.tap(find.widgetWithText(FxChoiceChip, 'Força'));
      await tester.pump();
      expect(chip().selected, isFalse);
    });

    testWidgets('"Outro" abre o campo de texto livre com rótulo', (tester) async {
      await _abrir(tester);

      expect(find.text('Outro objetivo'), findsNothing);
      await tester.tap(find.widgetWithText(FxChoiceChip, 'Outro'));
      await tester.pump();
      expect(find.text('Outro objetivo'), findsOneWidget);
    });
  });

  group('títulos e cabeçalho', () {
    testWidgets('grupo opcional explica e o antigo "Identidade" sumiu', (tester) async {
      await _abrir(tester);

      expect(find.text('Sobre o aluno · opcional'), findsOneWidget);
      expect(find.text('Identidade'), findsNothing);
      expect(find.text('Perfil inicial'), findsNothing);
    });

    testWidgets('seta de voltar no lugar do "Cancelar"', (tester) async {
      await _abrir(tester);

      expect(find.text('Cancelar'), findsNothing);
      expect(find.byTooltip('Voltar'), findsOneWidget);
    });

    testWidgets('voltar sem preencher sai; preenchido pergunta antes', (tester) async {
      await _abrir(tester);

      await _digitar(tester, 0, 'Beatriz');
      final voltar = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip != null && w.tooltip!.toLowerCase().contains('voltar'),
      );
      if (voltar.evaluate().isNotEmpty) {
        await tester.tap(voltar.first);
      } else {
        await tester.pageBack();
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Descartar cadastro?'), findsOneWidget);
    });
  });

  testWidgets('botão Cadastrar só habilita com nome e e-mail válidos', (tester) async {
    await _abrir(tester);

    FxLiquidPrimaryButton botao() => tester.widget(find.byType(FxLiquidPrimaryButton));
    expect(botao().onPressed, isNull);
    await _digitar(tester, 0, 'Beatriz Andrade');
    expect(botao().onPressed, isNull);
    await _digitar(tester, 1, 'sem-arroba');
    expect(botao().onPressed, isNull);
    await _digitar(tester, 1, 'bia@email.com');
    expect(botao().onPressed, isNotNull);
  });

  for (final escala in [1.0, 2.0]) {
    testWidgets('fonte ${escala}x em 360 de largura sem overflow', (tester) async {
      await _abrir(tester, largura: 360, textScale: escala);

      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
