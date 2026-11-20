import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/economia_de_dados_tile.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O Flutter quebra linha no hífen comum (U+002D): "Wi-" numa linha e "Fi"
/// na outra (20/11). Palavras que não podem partir usam o hífen inseparável
/// U+2011.
void main() {
  test(
    'app_pt.arb não tem Wi-Fi, e-mail, check-in e afins com hífen comum',
    () {
      final arb =
          jsonDecode(File('lib/l10n/app_pt.arb').readAsStringSync())
              as Map<String, dynamic>;
      final proibido = RegExp(
        r'\b(wi|e|check|drop|rest|back)-(fi|mails?|ins?|sets?|pause|off)\b',
        caseSensitive: false,
      );
      final achados = <String>[
        for (final e in arb.entries)
          if (!e.key.startsWith('@') &&
              e.value is String &&
              proibido.hasMatch(e.value as String))
            '${e.key}: ${e.value}',
      ];
      expect(achados, isEmpty, reason: 'Use U+2011 (‑) nessas palavras.');
    },
  );

  testWidgets(
    'Economizar dados: subtítulo em 320 pt não termina linha em hífen',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(body: EconomiaDeDadosTile()),
        ),
      );
      await tester.pumpAndSettle();
      const texto = 'No dado móvel, o vídeo só toca quando você pedir';
      final achado = find.text(texto);
      expect(achado, findsOneWidget);
      // Sem hífen comum no texto, nenhuma linha pode terminar partindo palavra.
      expect(texto.contains('-'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
