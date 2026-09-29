import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';

/// Lado visível do botão principal do compositor (enviar / gravar).
const double conversationComposerAcaoVisual = 36;

/// Botão principal do compositor: 36dp de visual, 48dp de alvo de toque.
class ConversationComposerAcao extends StatelessWidget {
  const ConversationComposerAcao({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TokensStrip.rButton);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: kMinInteractiveDimension,
            child: Center(
              child: SizedBox.square(
                dimension: conversationComposerAcaoVisual,
                child: Material(
                  color: color,
                  borderRadius: radius,
                  child: InkWell(
                    borderRadius: radius,
                    onTap: onPressed,
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
