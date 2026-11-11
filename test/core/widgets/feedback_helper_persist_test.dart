import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

void main() {
  testWidgets('aviso com ação some sozinho (persist: false)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => FeedbackHelper.showSuccessAction(
                        context,
                        'Trilha concluída!',
                        actionLabel: 'Desfazer',
                        onAction: () {},
                      ),
                  child: const Text('mostrar'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('mostrar'));
    await tester.pump();
    expect(find.text('Trilha concluída!'), findsOneWidget);

    // Entrada da animação, depois os 4 s do aviso.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Trilha concluída!'), findsNothing);
  });

  test('todo SnackBar com action em lib/ declara persist', () {
    final semPersist = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      var i = src.indexOf('SnackBar(');
      while (i >= 0) {
        final fim = src.indexOf(');', i);
        final trecho = src.substring(i, fim < 0 ? src.length : fim);
        // Só o bloco do SnackBar até o primeiro "action:" fechado.
        if (trecho.contains('action: SnackBarAction') &&
            !trecho.contains('persist:')) {
          semPersist.add(f.path);
        }
        i = src.indexOf('SnackBar(', i + 1);
      }
    }
    expect(semPersist, isEmpty, reason: 'SnackBar com ação precisa de persist');
  });
}
