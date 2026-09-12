import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../widgets/perfil_aluno_hub_body.dart';

class PerfilAlunoScreen extends ConsumerWidget {
  const PerfilAlunoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(alunoPerfilHomeProvider);
    final chrome = ShellChrome.of(context);
    final accent = BrandPalette.softened(Theme.of(context).colorScheme.primary);

    return fxScreenA11yScope(
      label: 'Meu perfil',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Meu perfil',
          showBack: false,
          subtitle: FxHubFreshness.fromFetchedAt(homeAsync.valueOrNull?.fetchedAt),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o perfil',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Meu perfil',
                subtitle: 'Conta, consentimentos e anamnese.',
                tips: const [
                  FxHelpTip(
                    'Cadastro',
                    'Toque no avatar ou em Editar cadastro para atualizar dados.',
                  ),
                  FxHelpTip(
                    'Completar',
                    'A barra inferior aparece enquanto o perfil não chega a 100%.',
                  ),
                ],
              ),
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: homeAsync.when(
            loading: () => const SkeletonList(count: 4),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: accent,
                  message: friendlyError(e),
                  title: FocuxMicrocopy.naoFoiPossivelCarregar,
                  onRetry: () => ref.invalidate(alunoPerfilHomeProvider),
                ),
            data: (home) => PerfilAlunoHubBody(home: home),
          ),
        ),
      ),
    );
  }
}
