import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_dock.dart';

void main() {
  testWidgets('FxDock renders correct number of tabs for personal', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: FxDock(
            items: FxDockItems.personal,
            currentIndex: 0,
            onTap: (_) {},
            isDark: false,
          ),
        ),
      ),
    );

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Alunos'), findsOneWidget);
    expect(find.text('IA'), findsOneWidget);
  });

  testWidgets('FxDock renders aluno tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: FxDock(
            items: FxDockItems.aluno,
            currentIndex: 0,
            onTap: (_) {},
            isDark: false,
          ),
        ),
      ),
    );

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Treinos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Alunos'), findsNothing);
  });
}
