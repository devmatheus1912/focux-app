import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/widgets/ia_copilot_insight_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  testWidgets('falha da prontidão mostra erro compacto com retry', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: IaCopilotReadinessCard(
            headline: 'Prontidão',
            modeDisplay: 'Treino',
            icon: Icons.bolt,
            promise: 'Promessa',
            checks: const [],
            alunoNome: 'Aluno',
            recoveryAsync: AsyncError<Never>(
              Exception('boom interno'),
              StackTrace.empty,
            ),
            onRetryRecovery: () => retried++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar a prontidão.'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, 1);
  });
}
