import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';

/// Hub Alunos error — paridade Perfil [`PerfilErrorScaffold`].
class AlunosErrorScaffold extends StatelessWidget {
  const AlunosErrorScaffold({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: FxErrorState(
        chromeOnDark: ShellChrome.of(context).isDark,
        primary: theme.colorScheme.primary,
        title: FocuxMicrocopy.erroAoCarregarAlunos,
        message: friendlyError(
          error,
          fallback: 'Não foi possível carregar seus alunos agora.',
        ),
        onRetry: onRetry,
      ),
    );
  }
}
