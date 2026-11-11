import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_icons.dart';
import 'package:focux_app/features/alunos/widgets/aluno_inset_form_field.dart';

Future<void> _montar(WidgetTester tester, {required int maxLines}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AlunoInsetFormField(
          controller: TextEditingController(),
          label: 'Mensagem',
          icon: FxIcons.notas,
          maxLines: maxLines,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('várias linhas: ícone no topo, fora do campo', (tester) async {
    await _montar(tester, maxLines: 5);

    final icone = tester.getRect(find.byIcon(FxIcons.notas));
    final campo = tester.getRect(find.byType(TextFormField));
    expect(find.byKey(const ValueKey('aluno-inset-icone-topo')), findsOneWidget);
    // Fica na primeira linha, não no meio da altura do campo.
    expect(icone.center.dy, lessThan(campo.center.dy));
    expect(icone.right, lessThanOrEqualTo(campo.left));
  });

  testWidgets('uma linha: ícone dentro do campo, como antes', (tester) async {
    await _montar(tester, maxLines: 1);

    expect(find.byKey(const ValueKey('aluno-inset-icone-topo')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(TextFormField),
        matching: find.byIcon(FxIcons.notas),
      ),
      findsOneWidget,
    );
  });
}
