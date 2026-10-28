import 'package:flutter/material.dart';

import 'fx_icon.dart';
import 'fx_tonal_button.dart';

/// Ação de navegação ("Ver todos", "Abrir ficha"): chip tonal com seta. Nunca
/// é só texto: tem fundo e borda, e a seta diz que leva a outra tela. Para
/// listas de "ver mais", prefira [FxLinkRow]; para ação que grava ou conclui,
/// use [FxTonalButton] ou o botão preenchido.
class FxActionLink extends StatelessWidget {
  const FxActionLink({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// Troca a seta final por outro ícone do conjunto [FxIcon] (ex.: 'plus').
  final String? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return FxTonalButton(
      label: label,
      compact: true,
      danger: destructive,
      onPressed: onTap,
      trailing: FxIcon(
        name: icon ?? 'chevron-right',
        size: 16,
        color: _cor(context),
      ),
    );
  }

  Color _cor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return destructive ? scheme.error : scheme.primary;
  }
}
