import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/jwt_session_identity.dart';

String _jwt(Map<String, Object?> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.sig';
}

void main() {
  final personal = _jwt({'sub': 'personal:1', 'personal_id': 1, 'exp': 1});
  final personalRenovado =
      _jwt({'sub': 'personal:1', 'personal_id': 1, 'exp': 2});
  final aluno = _jwt({'sub': 'aluno:7', 'personal_id': 1, 'aluno_id': 7});
  final outroTenant = _jwt({'sub': 'personal:1', 'personal_id': 2});

  test('mesma conta com token novo não conta como troca', () {
    expect(JwtSessionIdentity.isDifferentAccount(personal, personalRenovado),
        isFalse);
  });

  test('sem sessão anterior não é troca', () {
    expect(JwtSessionIdentity.isDifferentAccount(null, personal), isFalse);
    expect(JwtSessionIdentity.isDifferentAccount('', personal), isFalse);
  });

  test('outro usuário ou outro tenant é troca de conta', () {
    expect(JwtSessionIdentity.isDifferentAccount(personal, aluno), isTrue);
    expect(JwtSessionIdentity.isDifferentAccount(personal, outroTenant), isTrue);
  });

  test('token anterior ilegível conta como troca', () {
    expect(JwtSessionIdentity.isDifferentAccount('lixo', personal), isTrue);
  });
}
