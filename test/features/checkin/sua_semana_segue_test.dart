import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/sua_semana_rows.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

RotinaItem _treino(int id, String nome, int dia) =>
    RotinaItem(id: id, tipo: RotinaItemTipo.treino, treinoId: id, nome: nome, diaSemana: dia);

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('dia que segue a sequência mostra o próximo previsto', (tester) async {
    final rotina = RotinaFila(
      itens: [_treino(1, 'Treino A', 1), _treino(2, 'Treino B', 2), _treino(3, 'Treino C', 3)],
      diasAviso: const {6, 7},
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SuaSemanaBloco(rotina: rotina, hoje: DateTime(2026, 10, 26, 8)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Próximo da sequência · Treino A'), findsOneWidget);
    expect(find.text('Próximo da sequência · Treino B'), findsOneWidget);
    expect(find.text('Descanso'), findsNWidgets(2));
  });
}
