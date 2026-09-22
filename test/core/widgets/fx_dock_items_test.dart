import 'dart:io';

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
            items: FxDockItems.aluno(chatUnread: 2),
            currentIndex: 0,
            onTap: (_) {},
            isDark: false,
          ),
        ),
      ),
    );

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Treinos'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('9+'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Alunos'), findsNothing);
  });

  test('FxDock não usa poço nem underline de ativo', () {
    final dock = File('lib/core/widgets/fx_dock.dart').readAsStringSync();
    expect(dock, contains('FxSettingsLayout.iconSize'));
    expect(dock, contains('shellClearance'));
    expect(dock, isNot(contains('glowSize')));
    expect(dock, isNot(contains('RadialGradient')));
    expect(dock, isNot(contains('height: 3')));
  });
}
