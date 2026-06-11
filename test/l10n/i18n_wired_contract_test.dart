import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i18n S.delegate wired no MaterialApp', () {
    final mainDart = File('lib/main.dart').readAsStringSync();
    expect(mainDart, contains("import 'l10n/app_localizations.dart';"));
    expect(mainDart, contains('S.delegate'));
  });

  test('login screen usa S.of(context)', () {
    final login = File('lib/features/auth/screens/login_screen.dart').readAsStringSync();
    expect(login, contains('S.of(context)'));
    expect(login, contains('s.login'));
    expect(login, contains('s.email'));
    expect(login, contains('s.password'));
    expect(login, contains('s.forgotPassword'));
  });

  test('app_pt.arb contem chaves base', () {
    final arb = File('lib/l10n/app_pt.arb').readAsStringSync();
    expect(arb, contains('"login"'));
    expect(arb, contains('"email"'));
    expect(arb, contains('"password"'));
    expect(arb, contains('"forgotPassword"'));
  });
}
