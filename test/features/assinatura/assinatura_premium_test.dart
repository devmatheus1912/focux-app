import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assinatura layout estilo Claude app', () {
    final screen = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();
    final layout = File(
      'lib/features/assinatura/screens/claude_paywall_layout.dart',
    ).readAsStringSync();

    expect(screen, contains("part 'claude_paywall_layout.dart'"));
    expect(screen, contains('useMesh: false'));
    expect(screen, contains("title: 'Planos'"));
    expect(screen, contains('Gerenciar assinatura'));
    expect(screen, contains('FilledButton'));
    expect(screen, isNot(contains('useMesh: true')));
    expect(screen, isNot(contains('_PremiumPlanShowcase')));
    expect(screen, isNot(contains('_PlanSegmentBar')));

    expect(layout, contains('_ClaudePlanOptionTile'));
    expect(layout, contains('_ClaudeBillingSegment'));
    expect(layout, contains('_ClaudeUpgradeNudge'));
    expect(layout, contains('_ClaudeFeaturePanel'));
    expect(screen, contains('_resolveInitialPlanSelection'));
    expect(screen, contains('Fazer upgrade para Enterprise'));
    expect(screen, contains('Gerenciar assinatura na loja'));
  });
}
