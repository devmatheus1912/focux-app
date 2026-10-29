import 'package:flutter/material.dart';

/// Dono único do espaço do teclado nos shells (abas do personal e do aluno).
///
/// O `Scaffold` externo do shell já encolhe o corpo pela altura do teclado. Se
/// as telas das abas também encolhem (todas têm o próprio `Scaffold`), o
/// teclado é descontado duas vezes: o corpo some e o campo de mensagem do chat
/// fica colado no cabeçalho, com um vazio embaixo. Aqui o inset já tratado é
/// removido do que vai para dentro da aba.
class FxShellInsetOwner extends StatelessWidget {
  const FxShellInsetOwner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: child,
    );
  }
}
