import 'package:flutter/material.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import 'conversation_screen.dart';

class ChatAlunoScreen extends StatelessWidget {
  const ChatAlunoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Chat',
      child: const ConversationScreen.aluno(),
    );
  }
}
