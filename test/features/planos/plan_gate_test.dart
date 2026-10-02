import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_plan_lock_badge.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/utils/plan_gate.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

import '../../support/riverpod_seeds.dart';

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this.papel);

  final UserRole papel;

  @override
  UserRole? get currentRole => papel;

  @override
  AuthStatus build() => AuthStatus.authenticated;
}

class _GatedTile extends ConsumerWidget {
  const _GatedTile({required this.recurso, required this.onOpen});

  final String recurso;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = PlanGate.watch(ref, recurso);
    return ListTile(
      title: const Text('Abrir recurso'),
      trailing: PlanGate.lockBadge(r),
      onTap: PlanGate.tap(
        context,
        ref,
        recurso,
        featureName: 'Loja',
        action: onOpen,
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required SubscriptionPlan plano,
  required String recurso,
  required VoidCallback onOpen,
  UserRole papel = UserRole.personal,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seededPlanoFeatures(PlanoFeatures.fromJson({'plano': plano.name})),
        authProvider.overrideWith(() => _FakeAuth(papel)),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        home: Scaffold(body: _GatedTile(recurso: recurso, onOpen: onOpen)),
      ),
    ),
  );
}

void main() {
  setUp(DashboardHomeClientCache.clear);
  tearDown(DashboardHomeClientCache.clear);

  test('plano desconhecido não tranca (destino decide)', () {
    final r = PlanGate.resolve(null, PlanoRecursoKeys.loja);
    expect(r.liberado, isTrue);
    expect(r.planoMinimo, SubscriptionPlan.ENTERPRISE);
  });

  test('capability legada resolve a chave de recursos', () {
    final free = PlanoFeatures.fromJson({'plano': 'FREE'});
    expect(PlanGate.resolve(free, 'iaCopiloto').liberado, isFalse);
    expect(
      PlanGate.resolve(free, 'iaCopiloto').planoMinimo,
      SubscriptionPlan.PRO,
    );
  });

  testWidgets('trancado: mostra cadeado antes do toque e abre a sheet', (
    tester,
  ) async {
    var aberto = 0;
    await _pump(
      tester,
      plano: SubscriptionPlan.PRO,
      recurso: PlanoRecursoKeys.loja,
      onOpen: () => aberto++,
    );

    expect(find.byType(FxPlanLockBadge), findsOneWidget);
    expect(find.text('ENTERPRISE'), findsOneWidget);

    await tester.tap(find.text('Abrir recurso'));
    await tester.pumpAndSettle();

    expect(aberto, 0);
    expect(find.text('Desbloqueie no ENTERPRISE'), findsOneWidget);
  });

  testWidgets('liberado: sem cadeado, segue direto', (tester) async {
    var aberto = 0;
    await _pump(
      tester,
      plano: SubscriptionPlan.PRO,
      recurso: PlanoRecursoKeys.ia,
      onOpen: () => aberto++,
    );

    expect(find.byType(FxPlanLockBadge), findsNothing);
    await tester.tap(find.text('Abrir recurso'));
    await tester.pumpAndSettle();
    expect(aberto, 1);
    expect(find.textContaining('Desbloqueie'), findsNothing);
  });

  testWidgets('aluno nunca vê paywall', (tester) async {
    var aberto = 0;
    await _pump(
      tester,
      plano: SubscriptionPlan.FREE,
      recurso: PlanoRecursoKeys.habitos,
      onOpen: () => aberto++,
      papel: UserRole.aluno,
    );

    await tester.tap(find.text('Abrir recurso'));
    await tester.pumpAndSettle();
    expect(aberto, 0);
    expect(find.textContaining('Desbloqueie'), findsNothing);
  });
}
