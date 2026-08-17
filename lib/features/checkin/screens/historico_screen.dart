import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';

class HistoricoCheckinScreen extends ConsumerWidget {
  const HistoricoCheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historicoAsync = ref.watch(historicoCheckinProvider);

    return fxScreenA11yScope(
      label: 'Histórico de Treinos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Histórico de Treinos',
          onBack: () => safePopOrGo(context, '/checkin/treinos'),
        ),
        body: historicoAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 6),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: Theme.of(context).colorScheme.primary,
                message: friendlyError(e),
                title: FocuxMicrocopy.naoFoiPossivelCarregar,
                onRetry: () => ref.invalidate(historicoCheckinProvider),
              ),
          data:
              (historico) =>
                  historico.isEmpty
                      ? FxEmptyState(
                        icon: 'dumbbell',
                        title: 'Nenhum treino ainda',
                        subtitle: 'Seus treinos concluídos aparecerão aqui.',
                        action: FxEmptyAction(
                          label: 'Ver treinos disponíveis',
                          onTap: () => context.push('/checkin/treinos'),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh:
                            () async =>
                                ref.invalidate(historicoCheckinProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            8,
                            16,
                            100,
                          ),
                          itemCount: historico.length,
                          itemBuilder:
                              (context, i) => _HistoricoCard(
                                entry: historico[i],
                                isDark: isDark,
                              ),
                        ),
                      ),
        ),
      ),
    );
  }
}

class _HistoricoCard extends StatelessWidget {
  const _HistoricoCard({required this.entry, required this.isDark});

  final ExecucaoTreino entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    final concluido = entry.status == 'CONCLUIDO';
    final iconName = concluido ? 'circle-check' : 'calendar';
    final iconColor = concluido ? EagleTokens.good : EagleTokens.warn;
    final chipBg =
        concluido
            ? EagleTokens.good.withValues(alpha: 0.12)
            : EagleTokens.warn.withValues(alpha: 0.12);

    var dateLabel = '';
    if (entry.iniciadoEm != null) {
      try {
        dateLabel = fxDateFull(DateTime.parse(entry.iniciadoEm!));
      } catch (_) {
        dateLabel = entry.iniciadoEm!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: chrome.listCard(primary: concluido ? primary : null),
      child: Row(
        children: [
          FxIcon(name: iconName, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.treinoNome,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: chrome.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: chrome.mute),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
            ),
            child: Text(
              concluido ? 'Concluído' : 'Em andamento',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
