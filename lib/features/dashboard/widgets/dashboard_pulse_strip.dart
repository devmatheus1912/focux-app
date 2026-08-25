import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';

/// Pulso do dia — um grupo inset (ChatGPT/iOS), sem cards KPI soltos.
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
  /// Modo foco: esconde tendência/sparkline (só métricas).
  final bool collapseBody;
  /// Folga à direita quando o chip Ver prioridades está no overlay.
  final double trailingReserve;
  /// Copy do BFF (`pulse.emptyHint`) para o empty da tendência.
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final riscoAccent = riscoAlto > 0 ? EagleTokens.warn : primary;
    final width = MediaQuery.sizeOf(context).width;
    final tight = DashboardLayout.isCompact(width);
    final comfortable = DashboardLayout.isComfortable(width);
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
        !collapseBody &&
        (hasTrend || showEmptyTrendCta || (trendReady && !hideEmptyTrend));
    final showCta =
        !collapseBody &&
        showEmptyTrendCta &&
        emptyTrendCtaLabel != null &&
        onEmptyTrendCta != null;

    return dashboardEntryMotion(
      context: context,
      fade: fade,
      slideBegin: const Offset(0, 0.03),
      child: FxSettingsGroup(
        header: DashboardMicrocopy.pulsoOperacional,
        accent: primary,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: DashboardPulseChip(
                    icon: 'users',
                    value: alunosAtivos.toString(),
                    label: 'Ativos',
                    accent: ativosAccent,
                    isDark: isDark,
                    empty: alunosAtivos == 0,
                    showTrailingDivider: true,
                    onTap: onAtivos,
                  ),
                ),
                Expanded(
                  child: DashboardPulseChip(
                    icon: 'circle-check',
                    value: checkinsHoje.toString(),
                    label:
                        tight
                            ? 'Checks'
                            : DashboardMicrocopy.checkinsPulseLabel,
                    accent: checkinsAccent,
                    isDark: isDark,
                    empty: checkinsHoje == 0,
                    showTrailingDivider: true,
                    onTap: onCheckins,
                  ),
                ),
                Expanded(
                  child:
                      hideRiscoChip
                          ? DashboardPulseChip(
                            icon: 'calendar',
                            value: agendaHoje.toString(),
                            label: 'Agenda',
                            accent: agendaAccent,
                            isDark: isDark,
                            empty: agendaHoje == 0,
                            showTrailingDivider: false,
                            onTap: onAgenda,
                          )
                          : DashboardPulseChip(
                            icon:
                                riscoAlto > 0
                                    ? 'alert-triangle'
                                    : 'circle-check',
                            value: riscoAlto.toString(),
                            label: 'Risco',
                            accent: riscoAccent,
                            isDark: isDark,
                            empty: riscoAlto == 0,
                            showTrailingDivider: false,
                            onTap: onRisco,
                          ),
                ),
              ],
            ),
          ),
          if (showTrendRow)
            _PulseTrendRow(
              isDark: isDark,
              primary: primary,
              hasTrend: hasTrend,
              trendReady: trendReady,
              hideEmptyTrend: hideEmptyTrend,
              checkinsHoje: checkinsHoje,
              checkinsTrend: checkinsTrend,
              emptyHint: emptyHint,
              alunosAtivos: alunosAtivos,
              comfortable: comfortable,
              trailingReserve: trailingReserve,
              onTap: onCheckins,
              showDivider: showCta,
            ),
          if (showCta)
            FxSettingsTile(
              fxIcon: emptyTrendCtaLabel!.toLowerCase().contains('agenda')
                  ? 'calendar'
                  : 'dumbbell',
              label: emptyTrendCtaLabel!,
              value: '',
              onTap: onEmptyTrendCta!,
              showDivider: false,
            ),
        ],
      ),
    );
  }
}

class _PulseTrendRow extends StatelessWidget {
  const _PulseTrendRow({
    required this.isDark,
    required this.primary,
    required this.hasTrend,
    required this.trendReady,
    required this.hideEmptyTrend,
    required this.checkinsHoje,
    required this.checkinsTrend,
    required this.emptyHint,
    required this.alunosAtivos,
    required this.comfortable,
    required this.trailingReserve,
    required this.onTap,
    required this.showDivider,
  });

  final bool isDark;
  final Color primary;
  final bool hasTrend;
  final bool trendReady;
  final bool hideEmptyTrend;
  final int checkinsHoje;
  final List<double> checkinsTrend;
  final String? emptyHint;
  final int alunosAtivos;
  final bool comfortable;
  final double trailingReserve;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final caption = dashboardReadableCaption(context, isDark: isDark);
    final emptyDetail =
        alunosAtivos > 0
            ? DashboardMicrocopy.tendenciaVaziaBase
            : DashboardMicrocopy.tendenciaVaziaGeral;
    final hint = dashboardPulseEmptyHint(
      checkinsHoje: checkinsHoje,
      checkinsTrend: checkinsTrend,
      fromApi: emptyHint,
    );
    final sparkW = comfortable ? 88.0 : 72.0;
    final sparkH = comfortable ? 24.0 : 20.0;
    final subtitle =
        trendReady && !hasTrend && !hideEmptyTrend ? emptyDetail : null;

    return Semantics(
      button: true,
      label:
          !trendReady
              ? 'Tendência de check-ins carregando'
              : hasTrend
              ? 'Tendência de check-ins nos últimos 7 dias'
              : hint ?? emptyDetail,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: Row(
            children: [
              FxIcon(
                name: 'trend',
                size: FxSettingsLayout.iconSize,
                color: primary,
              ),
              const SizedBox(width: FxSettingsLayout.iconGap),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          showDivider
                              ? BorderSide(
                                color: chrome.line,
                                width: FxSettingsLayout.dividerThickness,
                              )
                              : BorderSide.none,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      TokensStrip.s3,
                      trailingReserve,
                      TokensStrip.s3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DashboardMicrocopy.tendencia7Dias,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.cardTitle(
                                  color: chrome.ink,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: caption,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                              color: caption,
                              fontSize: TokensStrip.fontBodySm,
                            ),
                          ),
                        Icon(
                          Icons.chevron_right,
                          size: FxSettingsLayout.chevronSize,
                          color: caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    required this.onTap,
    this.empty = false,
    this.showTrailingDivider = false,
  });

  final String icon;
  final String value;
  final String label;
  final Color accent;
  final bool isDark;
  final bool empty;
  final bool showTrailingDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Semantics(
      button: true,
      label: empty ? '$value $label, sem movimento hoje' : '$value $label',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border:
                  showTrailingDivider
                      ? Border(
                        right: BorderSide(
                          color: chrome.line,
                          width: FxSettingsLayout.dividerThickness,
                        ),
                      )
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FxIcon(
                    name: icon,
                    size: FxSettingsLayout.iconSize,
                    color: accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.metric(
                      fontSize: TokensStrip.fontBodySm,
                      color: chrome.ink,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.bodyMuted(
                      color: dashboardReadableCaption(
                        context,
                        isDark: isDark,
                      ),
                      height: 1.1,
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
