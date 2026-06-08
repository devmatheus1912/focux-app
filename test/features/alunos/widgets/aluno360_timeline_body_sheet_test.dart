import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_timeline_card.dart';

void main() {
  testWidgets('body sheet shows chat title without duplication', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showTimeline360BodySheet(
                      context,
                      const Timeline360Item(
                        at: null,
                        kind: 'Chat',
                        title: 'Chat · Personal',
                        body: 'Como foi seu último treino? Me manda carga e repetições.',
                        meta: 'PERSONAL',
                        priority: 'P3',
                        icon: Icons.chat_bubble_outline,
                        color: Colors.teal,
                        deepLink: '/alunos/42/chat',
                      ),
                      accent: Colors.teal,
                      isDark: false,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Chat · Personal'), findsOneWidget);
    expect(find.textContaining('Chat · Chat'), findsNothing);
    expect(find.text('Abrir chat'), findsOneWidget);
  });
}
