import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_descanso_relogio.dart';
import 'package:focux_app/features/checkin/widgets/checkin_timer_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('CheckinDescansoRelogio.ajustar', () {
    late DateTime agora;
    late CheckinDescansoRelogio relogio;
    var fim = 0;

    setUp(() {
      agora = DateTime(2026, 10, 28, 10);
      fim = 0;
      relogio = CheckinDescansoRelogio(
        agora: () => agora,
        onTick: () {},
        onFim: () => fim++,
      );
    });
    tearDown(() => relogio.dispose());

    test('+15 s soma ao que resta e ao total', () {
      relogio.iniciar(60);
      relogio.ajustar(15);
      expect(relogio.total, 75);
      expect(relogio.segundos, 75);
      expect(relogio.ativo, isTrue);
    });

    test('−15 s tira do que resta', () {
      relogio.iniciar(60);
      relogio.ajustar(-15);
      expect(relogio.segundos, 45);
      expect(relogio.total, 45);
    });

    test('tirar mais do que resta encerra sem tocar o aviso de fim', () {
      relogio.iniciar(30);
      agora = agora.add(const Duration(seconds: 20));
      relogio.ajustar(-15);
      expect(relogio.ativo, isFalse);
      expect(fim, 0);
    });

    test('sem descanso ativo não faz nada', () {
      relogio.ajustar(15);
      expect(relogio.ativo, isFalse);
    });
  });

  testWidgets('descanso mostra −15 s e +15 s e avisa o ajuste', (tester) async {
    final ajustes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Scaffold(
          body: CheckinRestFocusView(
            seconds: 60,
            totalSeconds: 60,
            onSkip: () {},
            onAjustar: ajustes.add,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.remove_rounded));
    expect(ajustes, [15, -15]);
  });
}
