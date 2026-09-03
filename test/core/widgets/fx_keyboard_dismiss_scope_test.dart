import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_keyboard_dismiss_scope.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';

void main() {
  testWidgets('tap outside unfocuses the field', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: FxKeyboardDismissScope(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focus),
                const SizedBox(height: 24),
                const Text('fora', key: Key('outside')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside')));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('FxShellAppBar without parent hides the back button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(appBar: FxShellAppBar(title: 'Hub'))),
    );

    expect(find.byTooltip('Voltar'), findsNothing);
  });

  testWidgets('FxShellAppBar onBack fires after unfocus', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: FxShellAppBar(title: 'Detalhe', onBack: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Voltar'));
    expect(tapped, isTrue);
  });

  test('FxKeyboardPopScope fecha o teclado em vez de pop', () {
    final src = File(
      'lib/core/widgets/fx_keyboard_dismiss_scope.dart',
    ).readAsStringSync();
    expect(src, contains('class FxKeyboardPopScope'));
    expect(src, contains('canPop: !keyboardOpen'));
    expect(src, contains('FxKeyboardDismissScope.dismiss()'));
  });
}
