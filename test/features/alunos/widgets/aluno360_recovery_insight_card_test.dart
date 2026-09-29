import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_recovery_insight_card.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _card(RecoverySnapshot snapshot) {
  return MaterialApp(
    locale: const Locale('pt'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: S.localizationsDelegates,
    home: Scaffold(
      body: Aluno360RecoveryInsightCard(
        recoveryAsync: AsyncData(snapshot),
        isDark: false,
        primary: const Color(0xFF12A3A3),
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('sem nota: anel "--" sem nível nem dica', (tester) async {
    await tester.pumpWidget(
      _card(
        const RecoverySnapshot(
          steps: 9000,
          caloriesBurned: 500,
          avgHeartRate: 60,
          sleepHours: 8,
          recoveryScore: null,
          recoveryLabel: 'Pronto para treinar',
          recoveryHint: 'Boa noite de sono.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('--'), findsOneWidget);
    expect(find.text('Prontidão wearable'), findsOneWidget);
    expect(find.text('Pronto para treinar'), findsNothing);
    expect(find.text('Boa noite de sono.'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('^Prontidão indisponível')),
      findsOneWidget,
    );
  });

  testWidgets('com nota: nível, dica e semântica de 0 a 100', (tester) async {
    await tester.pumpWidget(
      _card(
        const RecoverySnapshot(
          steps: 9000,
          caloriesBurned: 500,
          avgHeartRate: 60,
          sleepHours: 8,
          recoveryScore: 77,
          recoveryLabel: 'Pronto para treinar',
          recoveryHint: 'Boa noite de sono.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('77'), findsOneWidget);
    expect(find.text('Pronto para treinar'), findsOneWidget);
    expect(find.text('Boa noite de sono.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^Prontidão 77 de 100')),
      findsOneWidget,
    );
  });
}
