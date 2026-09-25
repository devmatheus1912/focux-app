import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/feature_gate.dart';
import 'package:focux_app/core/widgets/skeleton_loader.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

import '../../support/riverpod_seeds.dart';

DashboardHomeBundle _homeBundle(PlanoFeatures planoFeatures) {
  return DashboardHomeBundle(
    personal: DashboardData(
      totalAlunos: 1,
      alunosAtivos: 1,
      planoAtual: planoFeatures.plano.name,
      limiteAlunos: 3,
    ),
    commandCenter: CommandCenterData(
      agendaHoje: const [],
      alunosEmRisco: const [],
      alunosScore: const [],
      cobrancasPendentes: const [],
      autonomiaGargalos: const [],
      modoOperacao: const [],
      filaAcoes: const [],
    ),
    financeiro: FinanceiroDashboard(
      receitaMes: 0,
      receitaAcumulada: 0,
      ticketMedio: 0,
      totalInadimplentes: 0,
      previsaoReceita: 0,
      vencimentosProximos: const [],
      topAlunos: const [],
      evolucaoMensal: const [],
    ),
    planoFeatures: planoFeatures,
  );
}

Widget _gateApp({
  required SeededPlanoFeaturesNotifier notifier,
  required Widget gate,
}) {
  return ProviderScope(
    overrides: [
      planoFeaturesProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(home: gate),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DashboardHomeClientCache.clear);
  tearDown(DashboardHomeClientCache.clear);

  test('FeatureGate loading uses SkeletonList, never spinner-only', () {
    final gate = File('lib/core/widgets/feature_gate.dart').readAsStringSync();
    expect(gate, contains('SkeletonList'));
    expect(gate, isNot(contains('FxLoading')));
    expect(gate, isNot(contains('CircularProgressIndicator')));
    // Upsell só na tela travada — auto-sheet no mount foi removido de propósito.
    expect(gate, isNot(contains('UpgradePromptSheet.showIfAllowed')));
    expect(gate, contains('_LockedScreen'));
    expect(gate, contains('DashboardHomeClientCache.getIfFresh'));
    expect(gate, contains('seedFromHome'));
    expect(gate, contains('addPostFrameCallback'));

    final provider = File(
      'lib/features/planos/providers/plano_features_provider.dart',
    ).readAsStringSync();
    expect(provider, contains('DashboardHomeClientCache.getIfFresh'));
    expect(provider, contains('_applyFreshHomeCacheIfAny'));
    expect(provider, contains('_refreshIfBootstrapStillCurrent'));
  });

  testWidgets(
    'FeatureGate uses Home cache immediately — no loading-only flash',
    (tester) async {
      DashboardHomeClientCache.put(
        _homeBundle(
          const PlanoFeatures(
            plano: SubscriptionPlan.PRO,
            financeiro: true,
            agenda: true,
            relatorios: true,
            whiteLabel: false,
            iaCopiloto: true,
            migracaoFoto: true,
          ),
        ),
      );

      final notifier = SeededPlanoFeaturesNotifier(const AsyncLoading());

      await tester.pumpWidget(
        _gateApp(
          notifier: notifier,
          gate: const FeatureGate(
            featureName: 'Financeiro',
            requiredPlan: SubscriptionPlan.PRO,
            capability: 'financeiro',
            child: Text('gated-child'),
          ),
        ),
      );

      expect(find.text('gated-child'), findsOneWidget);
      expect(find.byType(SkeletonList), findsNothing);
    },
  );

  testWidgets(
    'FeatureGate stays locked from Home cache — does not flash paid child',
    (tester) async {
      DashboardHomeClientCache.put(
        _homeBundle(
          const PlanoFeatures(
            plano: SubscriptionPlan.FREE,
            financeiro: false,
            agenda: true,
            relatorios: false,
            whiteLabel: false,
            iaCopiloto: false,
            migracaoFoto: false,
          ),
        ),
      );

      final notifier = SeededPlanoFeaturesNotifier(const AsyncLoading());

      await tester.pumpWidget(
        _gateApp(
          notifier: notifier,
          gate: const FeatureGate(
            featureName: 'Financeiro',
            requiredPlan: SubscriptionPlan.PRO,
            capability: 'financeiro',
            lockedBuilder: Text('locked-ui'),
            child: Text('paid-content'),
          ),
        ),
      );

      expect(find.text('locked-ui'), findsOneWidget);
      expect(find.text('paid-content'), findsNothing);
      expect(find.byType(SkeletonList), findsNothing);
    },
  );

  testWidgets(
    'FeatureGate shows SkeletonList when loading and Home cache is empty',
    (tester) async {
      final notifier = SeededPlanoFeaturesNotifier(const AsyncLoading());

      await tester.pumpWidget(
        _gateApp(
          notifier: notifier,
          gate: const FeatureGate(
            featureName: 'Financeiro',
            requiredPlan: SubscriptionPlan.PRO,
            capability: 'financeiro',
            child: Text('gated-child'),
          ),
        ),
      );

      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.text('gated-child'), findsNothing);
    },
  );
}
