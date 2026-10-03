import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/services/apple_sign_in_service.dart';

void main() {
  test('nonce bruto tem o tamanho pedido e muda a cada chamada', () {
    final a = appleRawNonce();
    final b = appleRawNonce();
    expect(a.length, 32);
    expect(a, isNot(b));
    expect(appleRawNonce(16, Random(1)).length, 16);
  });

  test('Apple recebe o SHA-256 do nonce que vai para o backend', () {
    const raw = 'nonce-de-teste';
    expect(
      appleNonceHash(raw),
      sha256.convert(utf8.encode(raw)).toString(),
    );
    expect(appleNonceHash(raw), isNot(raw));
  });
}
