import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/sua_semana_rows.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';
import 'package:focux_app/l10n/app_localizations.dart';

/// Dia que passou sem treino diz "Não feito", não um traço nem "Segue a
/// sequência" (antes Qua aparecia com "—" e Qui/Sex com "Segue a sequência").
void main() {
  Future<void> pump(WidgetTester tester, Widget row) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: row),
    ),
  );

  testWidgets('ficha prevista e não feita mostra o nome e "Não feito"', (
    tester,
  ) async {
    await pump(
      tester,
      const SuaSemanaRow(
        diaNome: 'Qua',
        dia: DiaDaSemana(
          dia: 3,
          sessoes: [SessaoDaSemana(treinoId: 3, nome: 'C · Pernas')],
        ),
        hoje: false,
        status: false,
      ),
    );
    expect(find.text('C · Pernas'), findsOneWidget);
    expect(find.text('Não feito'), findsOneWidget);
  });

  testWidgets('dia da sequência que passou vira "Não feito"', (tester) async {
    await pump(
      tester,
      const SuaSemanaRow(
        diaNome: 'Qui',
        dia: DiaDaSemana(dia: 4, segueSequencia: true),
        hoje: false,
        status: false,
      ),
    );
    expect(find.text('Segue a sequência'), findsNothing);
    expect(find.text('Não feito'), findsOneWidget);
  });
}
