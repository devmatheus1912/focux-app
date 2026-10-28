import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_sheet_search_field.dart';

void main() {
  testWidgets('campo de busca que sai da tela não deixa o foco (teclado) órfão', (
    tester,
  ) async {
    var mostrar = true;
    late StateSetter troca;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              troca = setState;
              return mostrar
                  ? FxSheetSearchField(
                    dica: 'Buscar aluno',
                    autofocus: true,
                    onChanged: (_) {},
                  )
                  : const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.hasPrimaryFocus, isTrue);

    troca(() => mostrar = false);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
  });

  test('escolher aluno no Chat e no Financeiro solta o teclado antes de sair', () {
    final chat =
        File(
          'lib/features/chat/screens/chat_inbox_screen_state.part.dart',
        ).readAsStringSync();
    final financeiro =
        File(
          'lib/features/financeiro/widgets/financeiro_aluno_etapa.dart',
        ).readAsStringSync();
    expect(
      chat.indexOf('FxKeyboardDismissScope.dismiss();'),
      lessThan(chat.indexOf('Navigator.pop(ctx);')),
    );
    expect(financeiro, contains('FxKeyboardDismissScope.dismiss();'));
  });
}
