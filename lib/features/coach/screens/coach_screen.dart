import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../widgets/coach_proativo_card.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mensagens = ref.watch(coachMensagensProvider);

    return fxScreenA11yScope(
      label: 'Coach proativo',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Coach proativo',
          subtitle: 'Mensagens e orientações automáticas',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: mensagens.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 3),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(coachMensagensProvider),
              ),
          data:
              (msgs) =>
                  msgs.isEmpty
                      ? const FxEmptyState(
                        icon: 'spark',
                        title: 'Nenhuma orientação agora',
                        subtitle:
                            'O coach avisa aqui quando encontrar algo que merece sua atenção.',
                      )
                      : RefreshIndicator(
                        onRefresh:
                            () async => ref.invalidate(coachMensagensProvider),
                        child: ListView(
                          padding: const EdgeInsets.all(TokensStrip.s4),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [CoachProativoCard(isDark: isDark)],
                        ),
                      ),
        ),
      ),
    );
  }
}
