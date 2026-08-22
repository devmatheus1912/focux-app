import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';

/// Tappable pulse chips reuse [operationalMetricDecoration] from `OperationalMetricTile`
/// so dashboard KPIs match Aluno 360 visual language (display tiles stay read-only).
class DashboardDayPulseStrip extends StatelessWidget {
  const DashboardDayPulseStrip({
    super.key,
    required this.fade,
    required this.isDark,
    required this.alunosAtivos,
    required this.checkinsHoje,
    required this.checkinsTrend,
    required this.riscoAlto,
    required this.agendaHoje,
    required this.hideRiscoChip,
    required this.primary,
    required this.onAtivos,
    required this.onCheckins,
    required this.onAgenda,
    required this.onRisco,
    this.showEmptyTrendCta = false,
    this.hideEmptyTrend = false,
    this.emptyTrendCtaLabel,
    this.onEmptyTrendCta,
    this.collapseBody = false,
    this.trailingReserve = 0,
    this.emptyHint,
  });

  final Animation<double> fade;
  final bool isDark;
  final int alunosAtivos;
  final int checkinsHoje;
  final List<double> checkinsTrend;
  final int riscoAlto;
  final int agendaHoje;
  final bool hideRiscoChip;
  final Color primary;
  final VoidCallback onAtivos;
  final VoidCallback onCheckins;
  final VoidCallback onAgenda;
  final VoidCallback onRisco;
  final bool showEmptyTrendCta;
  /// Esconde “Tendência 7 dias” vazia quando Foco/aderência já narram o zero.
  final bool hideEmptyTrend;
  final String? emptyTrendCtaLabel;
  final VoidCallback? onEmptyTrendCta;
  /// Modo foco: esconde tendência/sparkline (só chips).
  final bool collapseBody;
  /// Folga à direita quando o chip Ver prioridades está no overlay.
  final double trailingReserve;
  /// Copy do BFF (`pulse.emptyHint`) para o empty da tendência.
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final riscoAccent =
        riscoAlto > 0 ? EagleTokens.warn : TokensStrip.badgeSuccess;
    final width = MediaQuery.sizeOf(context).width;
    final tight = DashboardLayout.isCompact(width);
    final comfortable = DashboardLayout.isComfortable(width);
    final gap = tight ? 6.0 : comfortable ? TokensStrip.s3 : TokensStrip.s2;
    final caption = dashboardReadableCaption(context, isDark: isDark);
    final ativosAccent = alunosAtivos > 0 ? primary : caption;
    final checkinsAccent = pulseCheckinsAccent(
      checkinsHoje: checkinsHoje,
      neutralAccent: caption,
      emptyAccent: alunosAtivos > 0 ? EagleTokens.warn : caption,
    );
    final agendaAccent = pulseAgendaAccent(
      agendaHoje: agendaHoje,
      primary: primary,
      caption: caption,
    );
    final trendReady = checkinsTrend.length >= 7;
    final hasTrend = trendReady && checkinsTrend.any((v) => v > 0);
    final showTrendRow =
        hasTrend || showEmptyTrendCta || (trendReady && !hideEmptyTrend);

    return dashboardEntryMotion(
      context: context,
      fade: fade,
      slideBegin: const Offset(0, 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DashboardMicrocopy.pulsoOperacional,
            style: dashboardSectionKickerStyle(context, isDark: isDark),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _PulseChipEntrance(
                  index: 0,
                  child: DashboardPulseChip(
                  icon: 'users',
                  value: alunosAtivos.toString(),
                  label: 'Ativos',
                  accent: ativosAccent,
                  isDark: isDark,
                  compact: tight,
                  empty: alunosAtivos == 0,
                  onTap: onAtivos,
                ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _PulseChipEntrance(
                  index: 1,
                  child: DashboardPulseChip(
                  icon: 'circle-check',
                  value: checkinsHoje.toString(),
                  label: tight ? 'Checks' : DashboardMicrocopy.checkinsPulseLabel,
                  accent: checkinsAccent,
                  isDark: isDark,
                  compact: tight,
                  empty: checkinsHoje == 0,
                  onTap: onCheckins,
                ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _PulseChipEntrance(
                  index: 2,
                  child:
                    hideRiscoChip
                        ? DashboardPulseChip(
                          icon: 'calendar',
                          value: agendaHoje.toString(),
                          label: 'Agenda',
                          accent: agendaAccent,
                          isDark: isDark,
                          compact: tight,
                          empty: agendaHoje == 0,
                          onTap: onAgenda,
                        )
                        : DashboardPulseChip(
                          icon:
                              riscoAlto > 0 ? 'alert-triangle' : 'circle-check',
                          value: riscoAlto.toString(),
                          label: 'Risco',
                          accent: riscoAccent,
                          isDark: isDark,
                          compact: tight,
                          empty: riscoAlto == 0,
                          onTap: onRisco,
                        ),
                ),
              ),
            ],
          ),
          if (showTrendRow) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final emptyDetail =
                  alunosAtivos > 0
                      ? DashboardMicrocopy.tendenciaVaziaBase
                      : DashboardMicrocopy.tendenciaVaziaGeral;
              final hint = dashboardPulseEmptyHint(
                checkinsHoje: checkinsHoje,
                checkinsTrend: checkinsTrend,
                fromApi: emptyHint,
              );
              final sparkW = collapseBody
                  ? (comfortable ? 88.0 : 72.0)
                  : (comfortable ? 112.0 : 88.0);
              final sparkH = collapseBody
                  ? (comfortable ? 24.0 : 20.0)
                  : (comfortable ? 28.0 : 24.0);
              return Semantics(
                label:
                    !trendReady
                        ? 'Tendência de check-ins carregando'
                        : hasTrend
                        ? 'Tendência de check-ins nos últimos 7 dias'
                        : hint ?? emptyDetail,
                child: InkWell(
                  onTap: onCheckins,
                  borderRadius: BorderRadius.circular(TokensStrip.rInput),
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: trailingReserve,
                      top: 4,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        if (!collapseBody)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DashboardMicrocopy.tendencia7Dias,
                                  style: dashboardSectionKickerStyle(
                                    context,
                                    isDark: isDark,
                                  ),
                                ),
                                if (trendReady && !hasTrend && !hideEmptyTrend) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    emptyDetail,
                                    style: dashboardCardSubtitleStyle(
                                      context,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        if (hasTrend)
                          FxSparkline(
                            data: checkinsTrend,
                            color: pulseCheckinsAccent(
                              checkinsHoje: checkinsHoje,
                              neutralAccent: caption,
                              emptyAccent: primary,
                            ),
                            width: sparkW,
                            height: sparkH,
                            strokeWidth: 2.0,
                            fill: true,
                          )
                        else if (trendReady &&
                            !hideEmptyTrend &&
                            trailingReserve <= 0)
                          Text(
                            '—',
                            style: FocuxHubTypography.metric(
                              color: dashboardReadableCaption(
                                context,
                                isDark: isDark,
                              ),
                              fontSize: FocuxHubTypography.metricEm,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (!collapseBody &&
              showEmptyTrendCta &&
              emptyTrendCtaLabel != null &&
              onEmptyTrendCta != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: emptyTrendCtaLabel,
                child: TextButton.icon(
                  onPressed: onEmptyTrendCta,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    foregroundColor: primary,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    emptyTrendCtaLabel!.toLowerCase().contains('agenda')
                        ? Icons.calendar_today_rounded
                        : Icons.fitness_center_rounded,
                    size: 16,
                  ),
                  label: Text(
                    emptyTrendCtaLabel!,
                    style: FocuxHubTypography.chip(primary)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
          ],
        ],
      ),
    );
  }
}

class _PulseChipEntrance extends StatelessWidget {
  const _PulseChipEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (TokensStrip.prefersReducedMotion(context)) return child;
    final delay = dashboardStaggerDelay(context, index);
    final base = dashboardMotionDuration(
      context,
      normal: const Duration(milliseconds: 280),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: base + delay,
      curve: Interval(
        delay.inMilliseconds / (base + delay).inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 6),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class DashboardPulseChip extends StatelessWidget {
  const DashboardPulseChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.compact,
    required this.onTap,
    this.empty = false,
  });

  final String icon;
  final String value;
  final String label;
  final Color accent;
  final bool isDark;
  final bool compact;
  final bool empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final comfortable =
        !compact &&
        DashboardLayout.isComfortable(MediaQuery.sizeOf(context).width);
    final iconSize = compact ? 22.0 : comfortable ? 26.0 : 24.0;
    final iconGlyph = compact ? 11.0 : comfortable ? 13.0 : 12.0;
    final valueSize =
        compact
            ? TokensStrip.fontBodySm
            : comfortable
            ? 16.0
            : 15.0;
    final labelSize = TokensStrip.fontBodySm;
    final hPad = compact ? 7.0 : comfortable ? 12.0 : 9.0;
    final vPad = compact ? 9.0 : comfortable ? 12.0 : 9.0;
    final emphasis = OperationalMetricEmphasis.normal;

    return Semantics(
      button: true,
      label: empty ? '$value $label, sem movimento hoje' : '$value $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: operationalMetricDecoration(
              accent: accent,
              isDark: isDark,
              radius: TokensStrip.rCard,
              emphasis: emphasis,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: isDark ? 0.22 : 0.14,
                          ),
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rInput,
                          ),
                        ),
                        child: Center(
                          child: FxIcon(
                            name: icon,
                            size: iconGlyph,
                            color: accent,
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 5 : 6),
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.metric(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 3),
                  Padding(
                    padding: EdgeInsets.only(
                      left: iconSize + (compact ? 5 : 6),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.chip(accent).copyWith(
                        fontSize: labelSize,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
