import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/utils/pix_qr_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  group('decodePixQrBase64', () {
    test('decodes raw base64', () {
      final bytes = utf8.encode('pix');
      final raw = base64Encode(bytes);
      expect(decodePixQrBase64(raw), bytes);
    });

    test('strips data-uri prefix', () {
      final bytes = utf8.encode('qr');
      final raw = 'data:image/png;base64,${base64Encode(bytes)}';
      expect(decodePixQrBase64(raw), bytes);
    });

    test('returns null on garbage', () {
      expect(decodePixQrBase64('not-base64!!!'), isNull);
      expect(decodePixQrBase64(''), isNull);
      expect(decodePixQrBase64(null), isNull);
    });
  });

  group('pixQrHasRenderablePayload', () {
    test('true when copia-e-cola present even without image', () {
      expect(
        pixQrHasRenderablePayload(
          pixCopiaECola: '00020126...',
          qrCodeBase64: '',
        ),
        isTrue,
      );
    });

    test('false when both empty', () {
      expect(
        pixQrHasRenderablePayload(pixCopiaECola: '  ', qrCodeBase64: ''),
        isFalse,
      );
    });
  });

  group('pixVencimentoLinha', () {
    final s = lookupS(const Locale('pt'));

    test('mostra a data de vencimento quando existe', () {
      expect(
        pixVencimentoLinha(
          s,
          mesReferencia: '2026-09-01',
          vencimento: '2026-09-10',
        ),
        'Vence em 10/09/2026',
      );
    });

    test('sem vencimento cai no mês de referência', () {
      expect(
        pixVencimentoLinha(s, mesReferencia: '2026-09-01', vencimento: ' '),
        'Referente a Setembro 2026',
      );
    });
  });
}
