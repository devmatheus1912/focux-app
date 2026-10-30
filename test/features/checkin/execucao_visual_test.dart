import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/checkin_header_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('topo: dois controles e barra com um segmento por exercício', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Scaffold(
          body: CheckinWorkoutHeader(
            treinoNome: 'Treino B',
            contextLine: '00:41',
            onBack: () {},
            onMais: () {},
            exercicioAtual: 1,
            totalExercicios: 3,
            progressoLeitura: '00:41 · exercício 1 de 3',
          ),
        ),
      ),
    );
    expect(find.byTooltip('Mais'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
    final barra = find.byKey(const ValueKey('checkin-barra-treino'));
    expect(find.descendant(of: barra, matching: find.byType(Expanded)), findsNWidgets(3));
  });

  test('vídeo sem fundo preto e sem corte', () {
    final fonte = File('lib/features/checkin/widgets/checkin_media_widgets.dart').readAsStringSync();
    expect(fonte, isNot(contains('color: Colors.black,')));
    expect(fonte, contains("ValueKey('checkin-video-caixa')"));
    expect(fonte, isNot(contains('BoxFit.cover')));
  });
}
