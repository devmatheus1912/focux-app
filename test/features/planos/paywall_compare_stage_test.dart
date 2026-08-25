import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/planos/paywall/paywall_compare_stage.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';

void main() {
  testWidgets('fillViewport estica o card e evita faixa vazia', (tester) async {
    const ink = Color(0xFF1A1A2E);
    const mute = Color(0xFF4B5563);
    const viewport = Size(390, 640);

    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: PaywallCompareStage(
              fillViewport: true,
              plans: const [
                SubscriptionPlan.FREE,
                SubscriptionPlan.PRO,
                SubscriptionPlan.ENTERPRISE,
              ],
              currentPlan: SubscriptionPlan.FREE,
              selectedPlan: SubscriptionPlan.PRO,
              comparisonRows: PaywallCatalog.comparisonFreeVsPro,
              billingPeriod: SubscriptionBillingPeriod.monthly,
              onSelectPlan: (_) {},
              onBillingPeriod: (_) {},
              ink: ink,
              mute: mute,
              isDark: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Assinar Pro'), findsOneWidget);
    expect(find.text('Alunos'), findsOneWidget);
    expect(find.text('R\$ 99,90/mês'), findsNothing);
    expect(tester.takeException(), isNull);

    final ia = tester.widget<Text>(find.text('200'));
    expect(ia.style?.fontFamily, contains('Barlow'));
    expect(ia.style?.fontWeight, FontWeight.w700);

    final titleCenter = tester.getCenter(find.text('Assinar Pro'));
    expect(titleCenter.dx, closeTo(viewport.width / 2, 8));

    final roi = PaywallCatalog.roiTagForPlan(SubscriptionPlan.PRO);
    expect(roi, isNotNull);
    expect(find.text(roi!), findsOneWidget);

    final freeW = tester.getSize(find.byKey(const ValueKey('paywall-tab-FREE'))).width;
    final proW = tester.getSize(find.byKey(const ValueKey('paywall-tab-PRO'))).width;
    final entW = tester
        .getSize(find.byKey(const ValueKey('paywall-tab-ENTERPRISE')))
        .width;
    expect(freeW, closeTo(proW, 0.5));
    expect(proW, closeTo(entW, 0.5));

    expect(find.text('Anual'), findsOneWidget);
    expect(find.text('2 meses grátis'), findsOneWidget);

    final headerPro = tester.getCenter(find.text('Pro').last);
    final alunosPaid = tester.getCenter(find.text('30'));
    expect((headerPro.dx - alunosPaid.dx).abs(), lessThan(12));

    final checkDx = tester.getCenter(find.byIcon(Icons.check_rounded).first).dx;
    expect((checkDx - headerPro.dx).abs(), lessThan(12));
  });
}
