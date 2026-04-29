import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login explains pending Google setup instead of showing a dead button', () {
    final login = File(
      'lib/features/auth/screens/login_screen.dart',
    ).readAsStringSync();

    expect(login, contains('AuthOperationalNotice'));
    expect(login, contains('_googleStatusTitle'));
    expect(login, contains('_googleStatusAction'));
    expect(login, contains('GOOGLE_WEB_CLIENT_ID'));
    expect(login, contains('Gerar o build com GOOGLE_WEB_CLIENT_ID'));
    expect(
      login,
      contains(
        'Google ainda nao esta configurado neste ambiente. Use e-mail e senha por enquanto.',
      ),
    );
  });

  test('password recovery surfaces SMTP action from environment status', () {
    final recovery = File(
      'lib/features/auth/screens/esqueci_senha_screen.dart',
    ).readAsStringSync();

    expect(recovery, contains('AuthOperationalNotice'));
    expect(recovery, contains("firstIssueFor('password_reset')"));
    expect(recovery, contains('_resetEnvironmentTitle'));
    expect(recovery, contains('_resetEnvironmentAction'));
    expect(recovery, contains('Configurar SMTP no ambiente real'));
  });

  test('operational notice has title detail and action slots', () {
    final notice = File(
      'lib/features/auth/widgets/auth_operational_notice.dart',
    ).readAsStringSync();

    expect(notice, contains('final String title;'));
    expect(notice, contains('final String text;'));
    expect(notice, contains('final String? action;'));
    expect(notice, contains('Color(0xFFFFB020)'));
  });
}
