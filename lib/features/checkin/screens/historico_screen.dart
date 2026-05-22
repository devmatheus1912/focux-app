import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_icon.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../../../core/widgets/fx_loading.dart';

class HistoricoCheckinScreen extends ConsumerWidget {
  const HistoricoCheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historicoAsync = ref.watch(historicoCheckinProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Histórico de Treinos'),
      ),
      body: historicoAsync.when(
        loading: () => const FxLoading(),
        error:
            (e, _) => FxEmptyState(
              icon: 'alert-triangle',
              title: 'Erro ao carregar',
              subtitle: e.toString(),
              action: FxEmptyAction(
                label: 'Tentar novamente',
                onTap: () => ref.invalidate(historicoCheckinProvider),
              ),
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
                          () async => ref.invalidate(historicoCheckinProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: historico.length,
                        itemBuilder:
                            (context, i) => _HistoricoCard(
                              entry: historico[i],
                              isDark: isDark,
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
    final concluido = entry.status == 'CONCLUIDO';
    final iconName = concluido ? 'circle-check' : 'calendar';
    final iconColor = concluido ? EagleTokens.good : EagleTokens.warn;
    final chipBg =
        concluido
            ? EagleTokens.good.withValues(alpha: 0.12)
            : EagleTokens.warn.withValues(alpha: 0.12);
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

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
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(EagleTokens.radiusMd),
        border: Border.all(color: line),
      ),
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
                    color: ink,
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
                    ).textTheme.bodySmall?.copyWith(color: mute),
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
              borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
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
