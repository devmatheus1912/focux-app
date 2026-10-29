import 'package:flutter/material.dart';

/// Dono único do espaço do teclado nos shells (abas do personal e do aluno).
///
/// O `Scaffold` externo do shell já encolhe o corpo pela altura do teclado. Se
/// as telas das abas também encolhem (todas têm o próprio `Scaffold`), o
/// teclado é descontado duas vezes: o corpo some e o campo de mensagem do chat
/// fica colado no cabeçalho, com um vazio embaixo. Aqui o inset já tratado é
/// removido do que vai para dentro da aba.
///
/// [removeTopPadding]: o shell já aplicou a área segura de cima (SafeArea). Sem
/// isso, a `AppBar` de cada tela soma a barra de status de novo e sobra um vão
/// no topo (chat e demais abas do aluno).
class FxShellInsetOwner extends StatelessWidget {
  const FxShellInsetOwner({
    super.key,
    required this.child,
    this.removeTopPadding = false,
  });

  final Widget child;
  final bool removeTopPadding;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: removeTopPadding,
      child: Builder(
        builder:
            (inner) => MediaQuery.removeViewInsets(
              context: inner,
              removeBottom: true,
              child: child,
            ),
      ),
    );
  }
}
