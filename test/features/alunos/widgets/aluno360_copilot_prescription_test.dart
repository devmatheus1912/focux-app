import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_prescription.dart';

void main() {
  testWidgets('Ver ação completa expands truncated prescription', (tester) async {
    const longAction =
        'Retomar contato com Beatriz e checar como está o treino, '
        'alinhar expectativas da semana e revisar aderência nos últimos dias.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: Aluno360CopilotPrescription(
              title: 'Prioridade do dia',
              action: longAction,
              reason: 'Priorize contato.',
              color: Colors.teal,
              showTitle: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ver ação completa'), findsOneWidget);

    await tester.tap(find.text('Ver ação completa'));
    await tester.pump();

    expect(find.text('Ocultar'), findsOneWidget);
    expect(find.text(longAction), findsOneWidget);
    expect(find.text('Ver ação completa'), findsNothing);
  });
}
