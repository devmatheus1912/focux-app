import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/utils/prontidao_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  final s = lookupS(const Locale('pt'));
  final agora = DateTime(2026, 9, 28, 21, 30);

  group('prontidaoNota', () {

  });

  group('prontidaoFrescor', () {
    test('snapshot de hoje nÃ£o mostra nada', () {
      expect(prontidaoFrescor(s, DateTime(2026, 9, 28), agora), isNull);
    });

    test('sem data de referÃªncia nÃ£o mostra nada', () {
      expect(prontidaoFrescor(s, null, agora), isNull);
    });

    test('data no futuro (fuso) conta como hoje', () {
      expect(prontidaoFrescor(s, DateTime(2026, 9, 29), agora), isNull);
    });

    test('ontem', () {
      expect(
        prontidaoFrescor(s, DateTime(2026, 9, 27), agora),
        'Atualizado ontem',
      );
    });

    test('data antiga em dd/MM', () {
      expect(
        prontidaoFrescor(s, DateTime(2026, 9, 5), agora),
        'Atualizado em 05/09',
      );
    });
  });

  group('alunoProntidaoSemantica', () {



  });
}
