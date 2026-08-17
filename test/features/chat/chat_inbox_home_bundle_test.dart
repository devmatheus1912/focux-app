import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/data/chat_repository.dart';

void main() {
  test('ChatInboxHomeBundle parses inbox aggregates', () {
    final bundle = ChatInboxHomeBundle.fromJson({
      'inbox': [
        {
          'alunoId': 7,
          'alunoNome': 'João',
          'ultimaMensagem': 'Oi',
          'ultimoRemetente': 'ALUNO',
          'enviadoEm': '2026-08-16T12:00:00',
          'naoLidas': 2,
        },
      ],
      'unread': [],
      'archived': [],
    });
    expect(bundle.inbox, hasLength(1));
    expect(bundle.inbox.first.alunoId, 7);
    expect(bundle.unread, isEmpty);
    expect(bundle.archived, isEmpty);
  });
}
