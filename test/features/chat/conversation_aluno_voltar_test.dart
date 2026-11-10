import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// O AlunoShell esconde o dock na aba do chat; sem voltar, o aluno fica preso
/// na conversa (bug de 10/11/2026). A conversa do aluno precisa da seta, que
/// troca para a Hoje do aluno.
void main() {
  test('conversa do aluno tem voltar para a Hoje do aluno', () {
    final screen = readScreenSourceBundle(
      'lib/features/chat/screens/conversation_screen.dart',
    );
    expect(screen, isNot(contains('showBack: _isPersonalMode')));
    expect(screen, contains("context.go('/dashboard/aluno')"));
  });

  test('o shell do aluno segue escondendo o dock só no chat', () {
    final shell = readScreenSourceBundle('lib/core/screens/aluno_shell.dart');
    expect(shell, contains('chatTabIndex'));
  });
}
