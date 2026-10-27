import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';
import 'fx_choice_chip.dart';

/// Atalhos de um toque (repetições, descanso, datas), com "Outro" opcional.
/// Quebra de linha em vez de rolar: tudo fica à vista em letra grande.
class FxQuickChips<T> extends StatelessWidget {
  const FxQuickChips({
    super.key,
    required this.itens,
    required this.selecionado,
    required this.onSelecionar,
    this.rotuloDe,
    this.outroRotulo,
    this.onOutro,
    this.outroSelecionado = false,
  });

  final List<T> itens;
  final T? selecionado;
  final ValueChanged<T> onSelecionar;

  /// Texto de cada atalho; sem ele, `toString()`.
  final String Function(T)? rotuloDe;
  final String? outroRotulo;
  final VoidCallback? onOutro;

  /// Valor atual não está entre os atalhos: "Outro" aparece marcado.
  final bool outroSelecionado;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TokensStrip.s2,
      children: [
        for (final item in itens)
          FxChoiceChip(
            label: rotuloDe?.call(item) ?? '$item',
            selected: !outroSelecionado && item == selecionado,
            onTap: () => onSelecionar(item),
          ),
        if (outroRotulo != null && onOutro != null)
          FxChoiceChip(
            label: outroRotulo!,
            selected: outroSelecionado,
            onTap: onOutro,
          ),
      ],
    );
  }
}
