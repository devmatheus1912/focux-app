import 'package:flutter/material.dart';

import '../brand/focux_microcopy.dart';
import '../theme/design_tokens.dart';
import 'fx_shell_scaffold.dart';

/// Erro de um bloco secundário: a mensagem e "Tentar novamente" no próprio
/// card, sem ocupar a tela como o [FxErrorState]. Sem [onRetry], só a
/// mensagem.
class FxInlineRetryTile extends StatelessWidget {
  const FxInlineRetryTile({
    super.key,
    required this.message,
    this.onRetry,
    this.margin = const EdgeInsets.only(bottom: 6),
  });

  final String message;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: FxSatelliteListTile(
        title: message,
        titleCase: false,
        // Fonte ampliada em 360dp quebra a mensagem em várias linhas.
        titleMaxLines: 4,
        margin: margin,
        onTap: onRetry,
        leading: const Icon(
          Icons.cloud_off_rounded,
          color: EagleTokens.bad,
          size: 20,
        ),
        subtitle:
            onRetry == null
                ? null
                : Text(
                  FocuxMicrocopy.tentarNovamente,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
      ),
    );
  }
}
