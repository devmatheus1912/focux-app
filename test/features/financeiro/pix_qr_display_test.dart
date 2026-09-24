import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/utils/pix_qr_display.dart';

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
}
