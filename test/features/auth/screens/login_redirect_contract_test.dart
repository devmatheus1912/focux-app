import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login honors safe from route after authentication', () {
    final login = File(
      'lib/features/auth/screens/login_screen.dart',
    ).readAsStringSync();

    expect(login, contains("_postLoginRedirect(context, isAluno: true)"));
    expect(login, contains("_postLoginRedirect(context, isAluno: false)"));
    expect(login, contains("GoRouterState.of(context).uri.queryParameters['from']"));
    expect(login, contains('String? _safePostLoginPath'));
    expect(login, contains("from.startsWith('//')"));
    expect(login, contains("from.contains('://')"));
    expect(login, contains('bool _isPublicAuthPath'));
    expect(login, contains('bool _isAlunoPath'));
    expect(login, contains('bool _isPersonalPath'));
    expect(login, contains("path == '/financeiro'"));
    expect(login, contains("path == '/dashboard/aluno'"));
  });

  test('student password change still overrides from route', () {
    final login = File(
      'lib/features/auth/screens/login_screen.dart',
    ).readAsStringSync();

    expect(login, contains('requiresChange'));
    expect(login, contains("'/aluno/definir-senha'"));
    expect(login, contains("_postLoginRedirect(context, isAluno: true)"));
  });
}
