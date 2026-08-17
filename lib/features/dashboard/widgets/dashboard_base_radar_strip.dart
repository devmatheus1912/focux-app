import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../constants/dashboard_layout.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_radar_items.dart';
import '../utils/dashboard_readability.dart';
import 'dashboard_collapsible_section.dart';
import 'dashboard_horizontal_scroll_peek.dart';

/// Strip “Radar da base” a partir de `commandCenter.alunosScore`.
class DashboardBaseRadarStrip extends StatelessWidget {
  const DashboardBaseRadarStrip({
    super.key,
    required this.isDark,
    required this.scores,
    this.initiallyExpanded = true,
    this.limit,
    this.quietChrome = false,
  });

  final bool isDark;
  final List<AlunoScoreResumo> scores;
  final bool initiallyExpanded;
  final int? limit;
  final bool quietChrome;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final take = limit ?? DashboardLayout.radarCardLimit(context);
    final items = dashboardRadarItems(scores, limit: take);
    if (items.isEmpty) return const SizedBox.shrink();

    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final cardW =
        DashboardLayout.isCompact(width)
            ? DashboardLayout.attentionCardWidthCompact
            : DashboardLayout.attentionCardWidth;

    return DashboardCollapsibleSection(
      title: DashboardMicrocopy.radarDaBase,
      collapsedHint:
          '${items.length} aluno${items.length == 1 ? '' : 's'} · ${DashboardMicrocopy.toqueParaVer}',
      isDark: isDark,
      initiallyExpanded: initiallyExpanded,
      quietChrome: quietChrome,
      child: DashboardHorizontalScrollPeek(
        showPeek: items.length > 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: TokensStrip.s2),
                _RadarCard(
                  item: items[i],
                  width: cardW,
                  ink: ink,
                  isDark: isDark,
                  index: i,
                  total: items.length,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.item,
    required this.width,
    required this.ink,
    required this.isDark,
    required this.index,
    required this.total,
  });

  final AlunoScoreResumo item;
  final double width;
  final Color ink;
  final bool isDark;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final nome = fxTitleCaseName(item.alunoNome);
    final label =
        '$nome, score ${item.score}. ${item.risco}. ${item.proximaAcao}. '
        'Item ${index + 1} de $total.';

    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        onTap: () {
          AnalyticsService.instance.track(
            ProductEvents.homeRadarTap,
            props: {
              'alunoId': item.alunoId,
              'score': item.score,
              'prioridade': item.prioridade,
            },
          );
          final url = item.acaoUrl.trim();
          if (url.isNotEmpty) {
            context.push(url);
          } else {
            context.push('/alunos/${item.alunoId}');
          }
        },
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color:
                isDark
                    ? EagleTokens.darkCard.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            border: Border.all(
              color: primary.withValues(alpha: isDark ? 0.28 : 0.18),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dashboardCardTitleStyle(ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.score}',
                    style: dashboardCardTitleStyle(primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: DashboardMicrocopy.scoreComoCalculamos,
                child: Text(
                  item.risco,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dashboardCardSubtitleStyle(
                    context,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.proximaAcao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: dashboardCardTitleStyle(ink).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
