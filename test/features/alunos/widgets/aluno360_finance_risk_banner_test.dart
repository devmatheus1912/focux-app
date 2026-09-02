import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_finance_risk_banner.dart';
import 'package:focux_app/features/dashboard/widgets/command_action_tile.dart';

void main() {
  testWidgets('finance risk banner exposes inset tile and labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Aluno360FinanceRiskBanner(alunoId: 42),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendência financeira'), findsOneWidget);
    expect(find.text('Abrir mensalidades deste aluno'), findsOneWidget);
    expect(find.byType(CommandActionTile), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Pendência financeira'),
      ),
      findsWidgets,
    );
  });
}
