import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/checkin_header_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, String nome) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: CheckinWorkoutHeader(
          treinoNome: nome,
          contextLine: '00:53',
          onBack: () {},
          onMais: () {},
        ),
      ),
    ),
  );
}

void main() {
  for (final nome in ['B', 'Treino com um nome bem comprido demais para caber na linha']) {
    testWidgets('botões ficam no canto direito: $nome', (tester) async {
      await _pump(tester, nome);
      final largura = tester.getSize(find.byType(Scaffold)).width;
      final sair = tester.getTopRight(find.text('Sair'));
      expect(largura - sair.dx, lessThan(48));
      expect(tester.takeException(), isNull);
    });
  }
}
