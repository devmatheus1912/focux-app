import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium chat uses branded bubbles and explicit retry state', () {
    final conversation = File(
      'lib/features/chat/screens/conversation_screen.dart',
    ).readAsStringSync();

    expect(conversation, contains('formatChatTextForDisplay'));
    expect(conversation, contains('BrandPalette.deep(accentColor)'));
    expect(conversation, contains('_loadFailed'));
    expect(conversation, contains('_ConversationErrorState'));
    expect(conversation, contains('Tentar novamente'));
    expect(conversation, contains('_Bubble('));
    expect(conversation, contains('accentColor: primary'));
  });

  test('student and personal chat routes keep the premium conversation surface', () {
    final aluno = File(
      'lib/features/chat/screens/chat_aluno_screen.dart',
    ).readAsStringSync();
    final personal = File(
      'lib/features/chat/screens/chat_screen.dart',
    ).readAsStringSync();

    expect(aluno, contains('ConversationScreen.aluno()'));
    expect(personal, contains('ConversationScreen.personal'));
  });
}
