import 'package:flutter/material.dart';

import '../brand/focux_microcopy.dart';
import '../theme/design_tokens.dart';
import 'fx_shell_scaffold.dart';

/// Erro de um bloco secundário: uma linha com "Tentar novamente", sem
/// ocupar a tela como o [FxErrorState].
class FxInlineRetryTile extends StatelessWidget {
  const FxInlineRetryTile({
    super.key,
    required this.message,
    required this.onRetry,
    this.margin = const EdgeInsets.only(bottom: 6),
  });

  final String message;
  final VoidCallback onRetry;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: FxSatelliteListTile(
        title: message,
        titleCase: false,
        margin: margin,
        leading: const Icon(
          Icons.cloud_off_rounded,
          color: EagleTokens.bad,
          size: 20,
        ),
        trailing: TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: const Text(FocuxMicrocopy.tentarNovamente),
        ),
      ),
    );
  }
}
