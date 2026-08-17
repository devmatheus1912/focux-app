import 'package:flutter/material.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Hub Perfil error — thin alias of canonical [FxErrorState].
class PerfilErrorScaffold extends StatelessWidget {
  const PerfilErrorScaffold({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FxShellScaffold(
      useMesh: true,
      body: FxErrorState(
        chromeOnDark: ShellChrome.of(context).isDark,
        primary: theme.colorScheme.primary,
        message: friendlyError(
          error,
          fallback: 'Não foi possível carregar seus dados agora.',
        ),
        onRetry: onRetry,
        title: 'Perfil indisponível',
      ),
    );
  }
}
