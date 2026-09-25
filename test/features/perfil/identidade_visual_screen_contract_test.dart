import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/providers/perfil_provider.dart';
import 'package:focux_app/features/perfil/screens/identidade_visual_screen.dart';
import 'package:focux_app/features/perfil/utils/identidade_visual_display.dart';
import 'package:focux_app/features/planos/data/plano_features_bff_cache.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

import '../../support/riverpod_seeds.dart';

void main() {
  setUp(() {
    DashboardHomeClientCache.clear();
    PlanoFeaturesBffCache.clear();
  });
  tearDown(() {
    DashboardHomeClientCache.clear();
    PlanoFeaturesBffCache.clear();
  });

  testWidgets('enterprise mostra salvar e preview brand', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _enterprisePerfil),
          _planoOverride(whiteLabel: true, plan: SubscriptionPlan.ENTERPRISE),
        ],
        child: const MaterialApp(home: IdentidadeVisualScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Identidade Visual'), findsOneWidget);
    expect(find.text(identidadeSalvarLabel(isSetup: false)), findsOneWidget);
    expect(find.textContaining('Visível no app do aluno'), findsOneWidget);
    expect(find.text(identidadeLightPreviewLabel()), findsOneWidget);
    expect(find.text(identidadeDarkPreviewLabel()), findsOneWidget);
    expect(find.text('Assinar Enterprise'), findsNothing);
    expect(find.byType(FxLiquidPrimaryButton), findsWidgets);
  });

  testWidgets('pro sem white-label mostra paywall', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _proPerfil),
          _planoOverride(whiteLabel: false, plan: SubscriptionPlan.PRO),
        ],
        child: const MaterialApp(home: IdentidadeVisualScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Assinar Enterprise'), findsOneWidget);
    expect(find.text('Recurso Enterprise'), findsOneWidget);
    expect(find.text(identidadeSalvarLabel(isSetup: false)), findsNothing);
  });

  testWidgets('selecionar paleta deixa o form dirty (confirmar ao sair)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _enterprisePerfil),
          _planoOverride(whiteLabel: true, plan: SubscriptionPlan.ENTERPRISE),
        ],
        child: const MaterialApp(home: IdentidadeVisualScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final midnight = find.text('Midnight Gold');
    await tester.scrollUntilVisible(
      midnight,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(midnight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byTooltip('Voltar').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(identidadeDiscardTitle()), findsOneWidget);
  });
}

Override _planoOverride({
  required bool whiteLabel,
  required SubscriptionPlan plan,
}) {
  return seededPlanoFeatures(
    PlanoFeatures(
      plano: plan,
      financeiro: true,
      agenda: true,
      relatorios: true,
      whiteLabel: whiteLabel,
      iaCopiloto: false,
      migracaoFoto: false,
    ),
  );
}

final _enterprisePerfil = PerfilPersonal(
  id: 7,
  nome: 'QA Coach',
  email: 'qa@example.com',
  telefone: '62982213003',
  cref: '123456-G/SP',
  especialidade: 'Hipertrofia',
  corPrimaria: '#0B4F5C',
  corSecundaria: '#3D9AAD',
  slogan: 'Movimento com método',
  slug: 'qa-demo-coach',
  plano: 'ENTERPRISE',
  chavePix: 'qa@example.com',
  descricaoProfissional: 'Especializado em biomecanica.',
  especialidades: 'Hipertrofia',
  instagram: '@qacoach',
);

final _proPerfil = PerfilPersonal(
  id: 8,
  nome: 'QA Pro',
  email: 'pro@example.com',
  corPrimaria: '#0B4F5C',
  corSecundaria: '#3D9AAD',
  slug: 'qa-pro',
  plano: 'PRO',
);
