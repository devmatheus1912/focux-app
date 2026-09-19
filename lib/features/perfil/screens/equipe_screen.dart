import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Equipe (RBAC) ainda não vai a produção — superfície "Em breve".
class EquipeScreen extends ConsumerWidget {
  const EquipeScreen({super.key});

  void _showHelp(BuildContext context) {
    showFxHelpSheet(
      context,
      title: 'Equipe',
      subtitle: 'Assistentes e permissões por papel.',
      tips: const [
        FxHelpTip(
          'Em breve',
          'Convites, papéis e acesso compartilhado ao mesmo studio entram numa próxima versão.',
          icon: 'users',
        ),
        FxHelpTip(
          'Enquanto isso',
          'Use um único login de personal. Quando a equipe abrir, você convida daqui.',
          icon: 'spark',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return fxScreenA11yScope(
      label: 'Equipe',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Equipe',
          subtitle: 'Em breve',
          onBack: () => safePopOrGo(context, '/perfil'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Sobre equipe',
              onTap: () => _showHelp(context),
            ),
          ],
        ),
        body: const FxContentWidthLimiter(
          child: Center(
            child: FxEmptyState(
              icon: 'users',
              title: 'Equipe em breve',
              subtitle:
                  'Convites e permissões para assistentes ainda não estão disponíveis nesta versão.',
            ),
          ),
        ),
      ),
    );
  }
}
