import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_redirect.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('form-check antigo cai nos vídeos do aluno', () {
    final routes = readScreenSourceBundle(
      'lib/core/router/app_router_aluno_routes.dart',
    );
    expect(routes, contains("path: '/aluno/form-check'"));
    expect(
      routes,
      contains("redirect: (context, state) => '/aluno/feedback-videos'"),
    );
    expect(routes, contains("path: '/aluno/feedback-videos'"));
    expect(routes, contains('AlunoFeedbackVideoScreen()'));
    expect(isAlunoOnlyLocation('/aluno/feedback-videos'), isTrue);
  });

  test('ia/aluno removido — IA só personal', () {
    final routes = readScreenSourceBundle(
      'lib/core/router/app_router_chrome_routes.dart',
    );
    expect(routes, isNot(contains("path: '/ia/aluno'")));
    expect(routes, isNot(contains('IaAlunoScreen')));
    expect(isAlunoOnlyLocation('/ia/aluno'), isFalse);
    expect(isPersonalOnlyLocation('/ia/chat'), isTrue);
  });

  test('post-login aluno não aceita deep link /ia/aluno', () {
    final util = readScreenSourceBundle(
      'lib/features/auth/utils/post_login_redirect.dart',
    );
    expect(util, isNot(contains("path == '/ia/aluno'")));
    expect(util, contains("path == '/gamificacao'"));
  });
}
