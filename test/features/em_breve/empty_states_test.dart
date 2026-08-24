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

  test('habit coaching e loja digital seguem na matriz', () {
    expect(
      PaywallCatalog.comparisonRows.any((r) => r.feature.contains('Habit')),
      isTrue,
    );
    expect(
      PaywallCatalog.comparisonRows.any(
        (r) => r.feature.toLowerCase().contains('loja'),
      ),
      isTrue,
    );
  });
}
