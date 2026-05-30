import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';

void main() {
  testWidgets('habitos empty state shows coaching message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FxEmptyState(
            icon: 'dumbbell',
            title: 'Nenhum hábito ainda',
            subtitle:
                'Seu personal ainda não cadastrou hábitos. Avise para começar sua jornada.',
          ),
        ),
      ),
    );
    expect(find.text('Nenhum hábito ainda'), findsOneWidget);
    expect(find.byType(FxEmptyState), findsOneWidget);
  });
}
