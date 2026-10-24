import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';
import 'fx_choice_chip.dart';

class FxChoiceItem<T> {
  const FxChoiceItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Fileira de [FxChoiceChip]. Rola na horizontal quando não cabe; com
/// `quebrar` os chips quebram de linha em vez de rolar.
class FxChoiceStrip<T> extends StatelessWidget {
  const FxChoiceStrip({
    super.key,
    required this.itens,
    required this.selecionado,
    required this.onSelecionar,
    this.quebrar = false,
  });

  final List<FxChoiceItem<T>> itens;
  final T? selecionado;
  final ValueChanged<T> onSelecionar;
  final bool quebrar;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final item in itens)
        FxChoiceChip(
          label: item.label,
          selected: item.value == selecionado,
          onTap: () => onSelecionar(item.value),
        ),
    ];
    if (quebrar) {
      return Wrap(spacing: TokensStrip.s2, children: chips);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, chip) in chips.indexed) ...[
            if (i > 0) const SizedBox(width: TokensStrip.s2),
            chip,
          ],
        ],
      ),
    );
  }
}
