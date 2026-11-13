import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/core/theme/fx_icons.dart';

void main() {
  testWidgets('FxEmptyState renders automacoes empty copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxEmptyState(
            icon: FxIcons.raio,
            title: 'Nenhum fluxo ativo',
            subtitle: 'Ative um template acima para começar automações.',
          ),
        ),
      ),
    );
    expect(find.text('Nenhum fluxo ativo'), findsOneWidget);
  });

  test('feedback em vídeo e loja digital seguem na matriz free vs pro', () {
    expect(
      PaywallCatalog.comparisonFreeVsPro.any(
        (r) => r.feature == 'Feedback em vídeo' && r.paid == '✓',
      ),
      isTrue,
    );
    expect(
      PaywallCatalog.comparisonFreeVsPro.any(
        // "Loja" virou "vendas" (SPEC planos 12/11).
        (r) => r.feature.toLowerCase().contains('vendas'),
      ),
      isTrue,
    );
  });
}
