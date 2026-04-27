import 'package:flutter/material.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatelessWidget {
  final int alunoId;
  final String alunoNome;

  const ChatScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  Widget build(BuildContext context) {
    return ConversationScreen.personal(
      alunoId: alunoId,
      alunoNome: alunoNome,
    );
  }
}
