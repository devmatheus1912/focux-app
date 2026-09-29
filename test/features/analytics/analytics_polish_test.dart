import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/analytics/data/analytics_repository.dart';
import 'package:focux_app/features/analytics/providers/analytics_provider.dart';
import 'package:focux_app/features/analytics/screens/analytics_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('analytics usa polish: dados reais, a11y e erro', () {
    final screen = readScreenSourceBundle(
      'lib/features/analytics/screens/analytics_screen.dart',
    );

    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('data.wau'));
    expect(screen, contains('data.mau'));
    expect(screen, contains('data.retencaoD30'));
    expect(screen, contains('Semantics('));
    expect(screen, isNot(contains('cac = 42')));
    expect(screen, isNot(contains('totalAlunos * 79')));
    expect(screen, isNot(contains('79.0 / (churn')));
  });

  testWidgets('herói e ajuda chamam de inadimplência, não de churn', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final dashboard = AnalyticsDashboard.fromJson({
      'totalAlunos': 10,
      'inadimplentes': 1,
      'wau': 7,
      'mau': 9,
      'taxaInadimplencia': 10.0,
      'retencaoD7': 80.0,
      'retencaoD30': 60.0,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsDashboardProvider.overrideWith((ref) async => dashboard),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inadimplência'), findsWidgets);
    expect(find.textContaining('Churn'), findsNothing);
    expect(find.textContaining('churn'), findsNothing);

    await tester.tap(find.byTooltip('Como usar Analytics'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('atividade, inadimplência e retenção'),
      findsOneWidget,
    );
    expect(find.textContaining('Churn'), findsNothing);
  });
}
