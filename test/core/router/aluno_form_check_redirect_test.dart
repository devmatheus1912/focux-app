import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno form-check redireciona para home (§38 hide)', () {
    final routes = readScreenSourceBundle(
      'lib/core/router/app_router_aluno_routes.dart',
    );
    expect(routes, contains("path: '/aluno/form-check'"));
    expect(routes, contains("redirect: (context, state) => '/dashboard/aluno'"));
    expect(routes, isNot(contains('FeedbackAlunoScreen')));
  });

  test('post-login aluno não aceita deep link /ia/aluno', () {
    final util = readScreenSourceBundle(
      'lib/features/auth/utils/post_login_redirect.dart',
    );
    expect(util, isNot(contains("path == '/ia/aluno'")));
    expect(util, contains("path == '/gamificacao'"));
  });
}
