import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';

/// Ícone que é o assunto da tela (tela vazia, bloqueio de plano): traço da
/// marca sobre a marca a 12%, raio do card. É o único ícone do app com fundo;
/// em lista o ícone fica solto.
class FxIconBadge extends StatelessWidget {
  const FxIconBadge(this.icon, {super.key, this.size = 64, this.iconSize = 28});

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: cor),
    );
  }
}
