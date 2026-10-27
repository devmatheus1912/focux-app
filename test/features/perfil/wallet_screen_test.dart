import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/providers/perfil_provider.dart';
import 'package:focux_app/features/perfil/screens/wallet_screen.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';
import '../../support/riverpod_seeds.dart';

PerfilPersonal _perfil({String? chave, String? tipo}) => PerfilPersonal(
  id: 1,
  nome: 'Pat',
  email: 'pat@example.com',
  plano: 'PRO',
  chavePix: chave,
  tipoChavePix: tipo,
);

Widget _app(PerfilPersonal perfil) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => const WalletScreen())],
  );
  return ProviderScope(
    overrides: [
      seededPlanoFeatures(PlanoFeatures.optimisticEnterprise),
      perfilWalletProvider.overrideWith((ref) async => perfil),
    ],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
        useMaterial3: true,
      ),
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('sem chave: "Cadastre sua chave" e o seletor com cinco tipos', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_perfil()));
    await _settle(tester);
    expect(find.text('Cadastre sua chave'), findsOneWidget);
    expect(find.text('Chave cadastrada'), findsNothing);
    expect(find.text('Pronta'), findsNothing);
    for (final tipo in ['CPF', 'CNPJ', 'E-mail', 'Celular', 'Aleatória']) {
      expect(find.text(tipo), findsWidgets, reason: tipo);
    }
    expect(find.text('Alterar chave'), findsNothing);
  });

  testWidgets('com chave: estado cadastrado, chave mascarada e Alterar chave', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_perfil(chave: '12345678901', tipo: 'CPF')));
    await _settle(tester);
    expect(find.text('Chave cadastrada'), findsOneWidget);
    // CPF mascarado, nunca inteiro
    expect(find.textContaining('***.456.789-**'), findsWidgets);
    expect(find.textContaining('123.456.789-01'), findsNothing);
    expect(find.text('Alterar chave'), findsOneWidget);
    expect(find.text('Copiar chave PIX'), findsOneWidget);
    // campo só abre depois de "Alterar chave"
    expect(find.byType(TextFormField), findsNothing);

    await tester.tap(find.text('Alterar chave'));
    await _settle(tester);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Alterar chave'), findsNothing);
  });

  testWidgets('trocar o tipo não muda o estado salvo do cartão', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_perfil()));
    await _settle(tester);
    await tester.tap(find.text('E-mail'));
    await _settle(tester);
    expect(find.text('Cadastre sua chave'), findsOneWidget);
  });

  for (final tela in kDynamicTypeTelas) {
    testWidgets('aguenta ${descreverTela(tela)}', (tester) async {
      usarDynamicTypeMaximo(tester, tela);
      await tester.pumpWidget(_app(_perfil()));
      await _settle(tester);
      final ex = tester.takeException();
      expect(ex, isNull, reason: ex?.toString());
    });
  }
}
