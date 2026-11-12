import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/fx_icons.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Rótulo à esquerda e − valor + à direita ("Quantas vezes por semana",
/// "Meta"). [valorTexto] mostra a unidade ("12 treinos").
class FxContador extends StatelessWidget {
  const FxContador({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
    this.valorTexto,
    this.min = 1,
    this.max = 999,
    this.passo = 1,
  });

  final String rotulo;
  final int valor;
  final String? valorTexto;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int passo;

  void _mudar(int novo) {
    final v = novo.clamp(min, max);
    if (v == valor) return;
    HapticFeedback.selectionClick();
    onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final texto = valorTexto ?? '$valor';
    return Semantics(
      label: '$rotulo: $texto',
      increasedValue: '${(valor + passo).clamp(min, max)}',
      decreasedValue: '${(valor - passo).clamp(min, max)}',
      onIncrease: valor < max ? () => _mudar(valor + passo) : null,
      onDecrease: valor > min ? () => _mudar(valor - passo) : null,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
        child: Row(
          children: [
            Expanded(
              child: Text(
                rotulo,
                style: FocuxHubTypography.body(color: chrome.ink),
              ),
            ),
            IconButton(
              tooltip: 'Menos',
              onPressed: valor > min ? () => _mudar(valor - passo) : null,
              icon: Icon(FxIcons.remover, color: primary),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 56),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.rotulo(color: chrome.ink),
              ),
            ),
            IconButton(
              tooltip: 'Mais',
              onPressed: valor < max ? () => _mudar(valor + passo) : null,
              icon: Icon(FxIcons.adicionar, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}
