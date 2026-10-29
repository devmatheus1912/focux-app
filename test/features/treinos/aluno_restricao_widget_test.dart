import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/anamnese/data/anamnese_repository.dart';
import 'package:focux_app/features/treinos/utils/aluno_restricao_match.dart';
import 'package:focux_app/features/treinos/widgets/aluno_restricao_strip.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  final anamnese = Anamnese.fromJson({
    'status': 'PREENCHIDA',
    'lesoes': 'Dor no joelho e na lombar',
    'alertas': ['Evitar impacto'],
  });

  testWidgets('faixa mostra as regiões, dispensa e abre o texto completo', (
    tester,
  ) async {
    var dispensou = 0;
    var abriu = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlunoRestricaoStrip(
            anamnese: anamnese,
            regioes: regioesDaAnamnese(anamnese),
            onDispensar: () => dispensou++,
            onVerAnamnese: () => abriu++,
          ),
        ),
      ),
    );
    expect(find.text('Atenção do aluno: joelho · lombar'), findsOneWidget);
    await tester.tap(find.byTooltip('Dispensar aviso'));
    expect(dispensou, 1);

    await tester.tap(find.textContaining('Atenção do aluno'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Aviso automático por palavras. Não substitui sua avaliação.'),
      findsOneWidget,
    );
    expect(find.text('Evitar impacto'), findsWidgets);
    await tester.tap(find.text('Ver anamnese'));
    expect(abriu, 1);
  });

  test('o texto da anamnese não vai para analytics', () {
    for (final caminho in [
      'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
      'lib/features/treinos/screens/add_exercicio_to_treino_screen_actions.part.dart',
      'lib/features/treinos/widgets/aluno_restricao_strip.dart',
      'lib/features/treinos/utils/aluno_restricao_match.dart',
    ]) {
      final linhas = File(caminho).readAsLinesSync();
      for (var i = 0; i < linhas.length; i++) {
        if (!linhas[i].contains('AnalyticsService')) continue;
        final janela = linhas.skip(i).take(8).join('\n').toLowerCase();
        expect(janela.contains('anamnese'), isFalse, reason: '$caminho:$i');
        expect(janela.contains('lesoes'), isFalse, reason: '$caminho:$i');
      }
    }
  });

  test('detalhe do exercício: acentos certos e sem "Atualizado agora"', () {
    final widgets =
        File(
          'lib/features/exercicios/screens/exercicio_detail_screen_widgets.part.dart',
        ).readAsStringSync();
    final estado =
        File(
          'lib/features/exercicios/screens/exercicio_detail_screen_state.part.dart',
        ).readAsStringSync();
    expect(widgets, contains("'Cuidados e substituições'"));
    expect(widgets, contains("'Contraindicações'"));
    expect(widgets, contains("'Dados técnicos'"));
    expect(widgets, isNot(contains('substituicoes')));
    expect(estado, isNot(contains('FxHubFreshness')));
  });
}
