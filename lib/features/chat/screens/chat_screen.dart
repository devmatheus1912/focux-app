import 'package:flutter/material.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import 'conversation_screen.dart';

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
    return fxScreenA11yScope(
      label: 'Chat',
      child: ConversationScreen.personal(
        alunoId: alunoId,
        alunoNome: alunoNome,
        initialDraft: initialDraft,
      ),
    );
  }
}
