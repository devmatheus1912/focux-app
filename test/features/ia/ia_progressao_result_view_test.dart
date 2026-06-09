import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/widgets/ia_progressao_result_view.dart';

void main() {
  const beatrizMarkdown = '''
Com base no histórico recente, sugiro progressão controlada.

| Exercício | Carga Atual | Carga Sugerida | Justificativa |
| --- | --- | --- | --- |
| Supino | 80kg 3x8 | 82,5kg 3x8 ou 80kg 3x10 | Aumentar 2,5kg mantendo reps ou manter carga e subir volume. |
''';

  testWidgets('renders Supino card legível em 390px sem overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: IaProgressaoResultView(
              markdown: beatrizMarkdown,
              alunoNome: 'Beatriz',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supino'), findsOneWidget);
    expect(find.text('80kg 3x8'), findsOneWidget);
    expect(find.text('82,5kg 3x8 ou 80kg 3x10'), findsOneWidget);
    expect(
      find.textContaining('Aumentar 2,5kg'),
      findsOneWidget,
    );
    expect(find.text('Copiar sugestão'), findsOneWidget);
    expect(find.textContaining('|'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
