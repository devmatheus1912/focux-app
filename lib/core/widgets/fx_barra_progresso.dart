import 'package:flutter/material.dart';

import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Barra fina de progresso ("7 de 12", "3 de 5 na semana").
/// [fracao] de 0 a 1; a trilha usa a linha do chrome.
class FxBarraProgresso extends StatelessWidget {
  const FxBarraProgresso({
    super.key,
    required this.fracao,
    this.cor,
    this.altura = 6,
  });

  final double fracao;
  final Color? cor;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final f = fracao.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(TokensStrip.rPill),
      child: SizedBox(
        height: altura,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: chrome.line),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: f,
              child: ColoredBox(
                color: cor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
