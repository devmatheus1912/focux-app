import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_home_header.dart';
import 'package:focux_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _abrir(
  WidgetTester tester, {
  required int conversas,
  VoidCallback? onConversas,
  double largura = 390,
}) async {
  tester.view.physicalSize = Size(largura * 3, 1800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [notificacoesNaoLidasProvider.overrideWith((ref) async => 0)],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Scaffold(
          body: DashboardHomeHeader(
            nomePersonal: 'Matheus Ribeiro',
            logoUrl: null,
            isDark: false,
            primary: EagleTokens.brandAccent,
            onProfileTap: () {},
            onHelp: () {},
            onQuickSearch: () {},
            onConversas: onConversas,
            conversasCount: conversas,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('dica do botão diz quantas conversas esperam resposta', () {
    expect(dashboardConversasTooltip(0), 'Conversas');
    expect(dashboardConversasTooltip(1), 'Conversas, 1 sem resposta');
    expect(dashboardConversasTooltip(12), 'Conversas, 12 sem resposta');
  });

  testWidgets('botão Conversas aparece com o selo e abre a caixa de entrada', (
    tester,
  ) async {
    var abriu = 0;
    await _abrir(tester, conversas: 3, onConversas: () => abriu++);
    expect(find.byTooltip('Conversas, 3 sem resposta'), findsOneWidget);
    // até 9 o selo é um ponto; o número vai na dica e no leitor de tela
    expect(find.text('9+'), findsNothing);
    await tester.tap(find.byTooltip('Conversas, 3 sem resposta'));
    expect(abriu, 1);
  });

  testWidgets('sem conversas pendentes: botão sem selo', (tester) async {
    await _abrir(tester, conversas: 0, onConversas: () {});
    expect(find.byTooltip('Conversas'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('sem callback, o botão não existe', (tester) async {
    await _abrir(tester, conversas: 2);
    expect(find.byTooltip('Conversas, 2 sem resposta'), findsNothing);
  });

  testWidgets('cabe em tela estreita (360)', (tester) async {
    await _abrir(tester, conversas: 12, onConversas: () {}, largura: 360);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Conversas, 12 sem resposta'), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);
  });
}
