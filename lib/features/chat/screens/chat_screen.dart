import 'package:flutter/material.dart';
import 'conversation_screen.dart';
import '../../../core/theme/tokens_strip.dart';

class ChatScreen extends StatelessWidget {
  final int alunoId;
  final String alunoNome;
  final String? initialDraft;

  const ChatScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.initialDraft,
  });

  @override
  Widget build(BuildContext context) {
    return ConversationScreen.personal(
      alunoId: alunoId,
      alunoNome: alunoNome,
      initialDraft: initialDraft,
    );
  }
}
