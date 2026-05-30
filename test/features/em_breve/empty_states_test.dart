import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';

void main() {
  testWidgets('FxEmptyState renders automacoes empty copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxEmptyState(
            icon: 'zap',
            title: 'Nenhum fluxo ativo',
            subtitle: 'Ative um template acima para começar automações.',
          ),
        ),
      ),
    );
    expect(find.text('Nenhum fluxo ativo'), findsOneWidget);
  });

  test('paywall topFeatures habit coaching is LIVE not coming soon', () {
    final habit = PaywallCatalog.topFeatures.firstWhere(
      (f) => f.title.contains('Habit'),
    );
    expect(habit.badge, 'LIVE');
    expect(habit.comingSoon, isFalse);
  });

  test('paywall loja digital feature is LIVE', () {
    final loja = PaywallCatalog.topFeatures.firstWhere(
      (f) => f.title.toLowerCase().contains('loja'),
    );
    expect(loja.comingSoon, isFalse);
    expect(loja.badge, 'LIVE');
  });
}
