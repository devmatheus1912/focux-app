import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login honors safe from route after authentication', () {
    final login = File(
      'lib/features/auth/screens/login_screen.dart',
    ).readAsStringSync();
    final util = File(
      'lib/features/auth/utils/post_login_redirect.dart',
    ).readAsStringSync();

    expect(login, contains("import '../utils/post_login_redirect.dart';"));
    expect(login, contains("_postLoginRedirect(context, isAluno: true)"));
    expect(login, contains("_postLoginRedirect(context, isAluno: false)"));
    expect(login, contains("GoRouterState.of(context).uri.queryParameters['from']"));
    expect(login, contains('safePostLoginPath(from, isAluno: isAluno)'));

    expect(util, contains('String? safePostLoginPath'));
    expect(util, contains("from.startsWith('//')"));
    expect(util, contains("from.contains('://')"));
    expect(util, contains('bool isPublicAuthPath'));
    expect(util, contains('bool isAlunoPath'));
    expect(util, contains('bool isPersonalPath'));
    expect(util, contains("path == '/financeiro'"));
    expect(util, contains("path == '/dashboard/aluno'"));
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
