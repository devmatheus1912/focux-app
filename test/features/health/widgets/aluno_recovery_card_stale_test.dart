import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/widgets/aluno_recovery_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, RecoverySnapshot? snapshot) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(body: AlunoRecoveryCard(snapshot: snapshot)),
    ),
  );
}

void main() {
  testWidgets('sem snapshot pede sincronizar a Saúde', (tester) async {
    await _pump(tester, null);
    expect(
      find.text('Sincronize a Saúde para ver a prontidão de hoje.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.watch_outlined), findsOneWidget);
  });

  testWidgets('com snapshot mostra nível e dica do dia', (tester) async {
    await _pump(
      tester,
      const RecoverySnapshot(
        steps: 8000,
        caloriesBurned: 400,
        avgHeartRate: 62,
        sleepHours: 7.5,
        recoveryScore: 82,
        recoveryLabel: 'Pronto para treinar',
        recoveryHint: 'Boa noite de sono.',
      ),
    );
    expect(find.text('Prontidão do dia'), findsOneWidget);
    expect(find.text('Pronto para treinar'), findsOneWidget);
    expect(find.text('Boa noite de sono.'), findsOneWidget);
    expect(find.textContaining('Sincronize'), findsNothing);
  });
}
