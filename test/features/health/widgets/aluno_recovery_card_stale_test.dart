import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/widgets/aluno_recovery_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';

final _agora = DateTime(2026, 9, 28, 9);

Future<void> _pump(WidgetTester tester, RecoverySnapshot? snapshot) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(body: AlunoRecoveryCard(snapshot: snapshot, now: _agora)),
    ),
  );
}

RecoverySnapshot _snap({int? score = 82, DateTime? dataReferencia}) =>
    RecoverySnapshot(
      dataReferencia: dataReferencia,
      steps: 8000,
      caloriesBurned: 400,
      avgHeartRate: 62,
      sleepHours: 7.5,
      recoveryScore: score,
      recoveryLabel: 'Pronto para treinar',
      recoveryHint: 'Boa noite de sono.',
    );

void main() {
  testWidgets('sem snapshot pede sincronizar a Saúde', (tester) async {
    await _pump(tester, null);
    expect(
      find.text('Sincronize a Saúde para ver a prontidão de hoje.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.watch_outlined), findsOneWidget);
  });

  testWidgets('com snapshot mostra nível, dica e nota de 100', (tester) async {
    await _pump(tester, _snap(dataReferencia: DateTime(2026, 9, 28)));
    expect(find.text('Prontidão do dia · 82/100'), findsOneWidget);
    expect(find.text('Pronto para treinar'), findsOneWidget);
    expect(find.text('Boa noite de sono.'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('Sincronize'), findsNothing);
    expect(find.textContaining('Atualizado'), findsNothing);
    expect(
      find.bySemanticsLabel(
        'Prontidão 82 de 100. Pronto para treinar. Boa noite de sono.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('snapshot de ontem mostra o frescor', (tester) async {
    await _pump(tester, _snap(dataReferencia: DateTime(2026, 9, 27)));
    expect(find.text('Atualizado ontem'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Atualizado ontem')),
      findsOneWidget,
    );
  });

  testWidgets('sem nota do servidor mostra -- e nenhum conselho', (
    tester,
  ) async {
    await _pump(tester, _snap(score: null));
    expect(find.text('--'), findsOneWidget);
    expect(find.text('Prontidão do dia'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('Boa noite de sono.'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('^Prontidão indisponível')),
      findsOneWidget,
    );
  });
}
