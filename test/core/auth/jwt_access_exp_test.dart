import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/jwt_access_exp.dart';

String _jwtWithExp(DateTime exp) {
  final header = base64Url.encode(utf8.encode('{"alg":"none"}'));
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'exp': exp.millisecondsSinceEpoch ~/ 1000})),
  );
  return '$header.$payload.sig';
}

void main() {
  test('JwtAccessExp lê exp e detecta skew', () {
    final soon = DateTime.now().toUtc().add(const Duration(minutes: 2));
    final jwt = _jwtWithExp(soon);
    expect(JwtAccessExp.expiresAt(jwt), isNotNull);
    expect(
      JwtAccessExp.isExpiringSoon(jwt, skew: const Duration(minutes: 5)),
      isTrue,
    );

    final later = DateTime.now().toUtc().add(const Duration(hours: 1));
    final fresh = _jwtWithExp(later);
    expect(
      JwtAccessExp.isExpiringSoon(fresh, skew: const Duration(minutes: 5)),
      isFalse,
    );
  });

  test('JwtAccessExp tolera JWT inválido', () {
    expect(JwtAccessExp.expiresAt('not-a-jwt'), isNull);
    expect(JwtAccessExp.isExpiringSoon('x.y'), isFalse);
  });
}
