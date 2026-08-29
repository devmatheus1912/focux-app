import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_inset_picker_option.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_taxonomy_labels.dart';
import 'package:focux_app/features/exercicios/widgets/add_exercicio_enum_picker_sheet.dart';

void main() {
  testWidgets('enum picker usa linhas inset e retorna seleção', (tester) async {
    Dificuldade? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () async {
                    picked = await showAddExercicioEnumPicker<Dificuldade>(
                      context,
                      title: 'Dificuldade',
                      contextLabel: 'Novo exercício',
                      icon: Icons.signal_cellular_alt_rounded,
                      values: Dificuldade.values,
                      labels: TaxonomyLabels.dificuldade,
                      selected: Dificuldade.iniciante,
                    );
                  },
                  child: const Text('abrir'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(FxInsetPickerOption), findsWidgets);
    expect(find.text('Dificuldade'), findsOneWidget);
    expect(find.text('Novo exercício'), findsOneWidget);

    final avancado = TaxonomyLabels.dificuldade[Dificuldade.avancado]!;
    await tester.tap(find.text(avancado));
    await tester.pumpAndSettle();

    expect(picked, Dificuldade.avancado);
    expect(find.byType(FxInsetPickerOption), findsNothing);
  });
}
