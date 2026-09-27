import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/widgets/aluno_recovery_card.dart';

Future<void> _pump(WidgetTester tester, {required bool stale, bool hist = true}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AlunoRecoveryCard(
            isDark: false,
            snapshot: null,
            hasWearableHistory: hist,
            recoveryStale: stale,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('prontidão velha pede sincronizar em vez de sumir', (tester) async {
    await _pump(tester, stale: true);
    expect(find.text('Sincronize a Saúde para ver a prontidão de hoje.'), findsOneWidget);
  });

  testWidgets('sem histórico e sem stale continua escondido', (tester) async {
    await _pump(tester, stale: false, hist: false);
    expect(find.byType(InkWell), findsNothing);
    expect(find.textContaining('Sincronize'), findsNothing);
  });
}
