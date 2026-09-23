import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';

void main() {
  testWidgets('renders title and icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FxEmptyState(icon: 'dumbbell', title: 'Nenhum treino'),
        ),
      ),
    );

    expect(find.text('Nenhum treino'), findsOneWidget);
  });

  testWidgets('renders action button when provided', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxEmptyState(
            icon: 'dumbbell',
            title: 'Nenhum treino',
            action: FxEmptyAction(
              label: 'Iniciar treino',
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Iniciar treino'));
    expect(tapped, isTrue);
  });

  testWidgets('no action button when action is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FxEmptyState(icon: 'dumbbell', title: 'Nenhum treino'),
        ),
      ),
    );

    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('quiet mode stays top-aligned without giant icon box', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FxEmptyState(
            icon: 'chat',
            title: 'Nenhuma conversa ainda',
            subtitle: 'Escolha um aluno para começar.',
            quiet: true,
          ),
        ),
      ),
    );

    expect(find.text('Nenhuma conversa ainda'), findsOneWidget);
    expect(find.byType(Align), findsWidgets);
  });
}
