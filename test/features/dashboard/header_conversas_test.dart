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
  VoidCallback? onCopiloto,
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
            onQuickSearch: () {},
            onCopiloto: onCopiloto,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Conversas virou aba (SPEC-navegacao-personal): o topo da Hoje tem
  // Buscar · IA Focux · Notificações, sem selo (o Copiloto virou IA Focux em 12/11).
  testWidgets('botão do Copiloto no topo, sem selo, abre o Copiloto', (
    tester,
  ) async {
    var abriu = 0;
    await _abrir(tester, onCopiloto: () => abriu++);
    expect(find.byTooltip('IA Focux'), findsOneWidget);
    expect(find.byTooltip('Conversas'), findsNothing);
    await tester.tap(find.byTooltip('IA Focux'));
    expect(abriu, 1);
  });

  testWidgets('sem callback, o botão não existe', (tester) async {
    await _abrir(tester);
    expect(find.byTooltip('IA Focux'), findsNothing);
  });

  testWidgets('cabe em tela estreita (360)', (tester) async {
    await _abrir(tester, onCopiloto: () {}, largura: 360);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('IA Focux'), findsOneWidget);
  });
}
