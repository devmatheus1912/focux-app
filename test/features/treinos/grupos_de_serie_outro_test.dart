import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/grupos_de_serie.dart';
import 'package:focux_app/features/treinos/widgets/grupos_de_serie_editor.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('atalhos de reps por papel; back-off segue as válidas do bloco', () {
    expect(atalhosDoGrupo(PapelDaSerie.aquecimento, 'TRABALHO'), ['15', '12', '10', '8']);
    expect(atalhosDoGrupo(PapelDaSerie.ajuste, 'TRABALHO'), ['5', '3', '2', '1']);
    expect(atalhosDoGrupo(PapelDaSerie.backoff, 'TRABALHO'), ['6-8', '8-12', '12-15', '15-20']);
  });

  Future<List<GrupoDeSeries>> abrir(WidgetTester t, GrupoDeSeries grupo) async {
    var antes = [grupo];
    await t.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: GruposDeSerieEditor(
            antes: antes,
            depois: const [],
            resumoValidas: '3 × 8-12',
            sugerir: (p) => grupoSugerido(p, seriesValidas: 3, repsValidas: '8-12'),
            onChanged: (a, _) => setState(() => antes = a),
          ),
        ),
      ))),
    );
    await t.tap(find.textContaining('Aquecimento').first);
    await t.pumpAndSettle();
    return antes;
  }

  testWidgets('"Outro" das reps grava valor livre e ele fica no lugar do Outro', (t) async {
    await abrir(t, const GrupoDeSeries(papel: PapelDaSerie.aquecimento, series: 2, repeticoes: '12'));
    await t.tap(find.text('Outro').first);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), '20');
    await t.tap(find.text('Aplicar'));
    await t.pumpAndSettle();
    expect(find.text('20'), findsWidgets);
  });

  testWidgets('tocar na carga abre o teclado e aceita 7,5 kg', (t) async {
    await abrir(t, const GrupoDeSeries(papel: PapelDaSerie.aquecimento, series: 2, repeticoes: '12'));
    // Sem carga o valor aparece como "—"; tocar nele abre o teclado.
    await t.ensureVisible(find.text('—'));
    await t.tap(find.text('—'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, '7,5');
    await t.pump();
    await t.ensureVisible(find.text('Aplicar').last);
    await t.tap(find.text('Aplicar').last);
    await t.pumpAndSettle();
    expect(find.text('7,5 kg'), findsOneWidget);
  });
}
