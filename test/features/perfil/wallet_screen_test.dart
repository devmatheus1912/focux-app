import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/confirmar_no_aparelho.dart';
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

class _AparelhoFalso implements ConfirmarNoAparelho {
  _AparelhoFalso({this.confirma = true});
  final bool confirma;
  final motivos = <String>[];

  @override
  Future<bool> confirmar(String motivo) async {
    motivos.add(motivo);
    return confirma;
  }
}

Widget _app(PerfilPersonal perfil, {ConfirmarNoAparelho? aparelho}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => const WalletScreen())],
  );
  return ProviderScope(
    overrides: [
      seededPlanoFeatures(PlanoFeatures.optimisticEnterprise),
      perfilWalletProvider.overrideWith((ref) async => perfil),
      confirmarNoAparelhoProvider.overrideWithValue(
        aparelho ?? _AparelhoFalso(),
      ),
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

  testWidgets('sem chave: formulário com cinco tipos, sem banco e sem Salvar', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_perfil()));
    await _settle(tester);
    for (final tipo in ['CPF', 'CNPJ', 'E-mail', 'Celular', 'Aleatória']) {
      expect(find.text(tipo), findsWidgets, reason: tipo);
    }
    expect(find.text('Alterar chave'), findsNothing);
    expect(find.text('Banco'), findsNothing);
    expect(find.text('Recebimentos'), findsNothing);
    // Nada alterado: sem botão de salvar.
    expect(find.text('Salvar chave'), findsNothing);
  });

  testWidgets('com chave: mascarada, Alterar e Copiar; campo fechado', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_perfil(chave: '12345678901', tipo: 'CPF')));
    await _settle(tester);
    expect(find.text('CPF · ***.456.789-**'), findsOneWidget);
    expect(find.textContaining('123.456.789-01'), findsNothing);
    expect(find.text('Alterar chave'), findsOneWidget);
    expect(find.text('Copiar chave'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Salvar chave'), findsNothing);

    await tester.tap(find.text('Alterar chave'));
    await _settle(tester);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Manter a chave atual'), findsOneWidget);
  });

  testWidgets('trocar a chave mostra o valor novo e pede o aparelho', (
    tester,
  ) async {
    telaAlta(tester);
    final aparelho = _AparelhoFalso(confirma: false);
    await tester.pumpWidget(
      _app(_perfil(chave: '12345678901', tipo: 'CPF'), aparelho: aparelho),
    );
    await _settle(tester);
    await tester.tap(find.text('Alterar chave'));
    await _settle(tester);
    await tester.tap(find.text('E-mail'));
    await _settle(tester);
    await tester.enterText(find.byType(TextFormField), 'joana@gmail.com');
    await _settle(tester);
    expect(find.text('Salvar chave'), findsOneWidget);

    await tester.tap(find.text('Salvar chave'));
    await _settle(tester);
    expect(find.text('Trocar a chave PIX?'), findsOneWidget);
    expect(find.textContaining('E-mail · j***@gmail.com'), findsOneWidget);

    await tester.tap(find.text('Trocar chave'));
    await _settle(tester);
    expect(aparelho.motivos, hasLength(1));
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
