import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/dashboard_provider.dart';
import '../utils/aluno_home_view.dart';
import '../widgets/aluno_ferramentas_catalogo.dart';

/// O que o plano do personal libera para o aluno, agrupado por tarefa.
/// Treinos, Chat e Saúde ficam na barra de baixo e não entram aqui.
class AlunoFerramentasScreen extends ConsumerWidget {
  const AlunoFerramentasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final homeAsync = ref.watch(alunoDashboardHomeProvider);

    return fxScreenA11yScope(
      label: s.alunoFerramentasTitulo,
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: s.alunoFerramentasTitulo,
          actions: [
            FxHelpIconButton(
              tooltip: s.alunoFerramentasAjudaTooltip,
              onTap: () => showFxHelpSheet(
                context,
                title: s.alunoFerramentasTitulo,
                subtitle: s.alunoFerramentasAjudaSubtitulo,
                tips: [
                  FxHelpTip(
                    s.alunoFerramentasAjudaGruposTitulo,
                    s.alunoFerramentasAjudaGrupos,
                  ),
                  FxHelpTip(
                    s.alunoFerramentasAjudaPlanoTitulo,
                    s.alunoFerramentasAjudaPlano,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: homeAsync.when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: FxSettingsLayout.pageInset),
            child: SkeletonList(count: 6),
          ),
          error: (e, _) => FxErrorState(
            chromeOnDark: Theme.of(context).brightness == Brightness.dark,
            primary: Theme.of(context).colorScheme.primary,
            message: friendlyError(e),
            onRetry: () => ref.invalidate(alunoDashboardHomeProvider),
          ),
          data: (home) {
            final view = buildAlunoHomeView(home, agendaReviewed: false);
            return FxContentWidthLimiter(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  0,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s5,
                ),
                children: [AlunoFerramentasCatalogo(liberada: view.ferramentaLiberada)],
              ),
            );
          },
        ),
      ),
    );
  }
}
