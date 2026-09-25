import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';

/// Pulso do dia — até 3 métricas S1 + tendência. Sem inset.
class DashboardDayPulseStrip extends StatelessWidget {
  const DashboardDayPulseStrip({
    super.key,
    required this.fade,
    required this.isDark,
    required this.alunosAtivos,
    required this.checkinsHoje,
    required this.checkinsTrend,
    required this.riscoAlto,
    required this.primary,
    required this.onAtivos,
    required this.onCheckins,
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
  final Color primary;
  final VoidCallback onAtivos;
  final VoidCallback onCheckins;
  final VoidCallback onRisco;
  final bool showEmptyTrendCta;
  /// Esconde “7 dias” vazia quando Foco/aderência já narram o zero.
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
    final comfortable = DashboardLayout.isComfortable(width);
    final caption = dashboardReadableCaption(context, isDark: isDark);
    final checkinsAccent = pulseCheckinsAccent(
      checkinsHoje: checkinsHoje,
      neutralAccent: caption,
      emptyAccent: alunosAtivos > 0 ? EagleTokens.warn : caption,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DashboardMicrocopy.pulsoOperacional,
            style: FxSettingsLayout.sectionHeader(
              color: dashboardReadableCaption(context, isDark: isDark),
            ),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          InkWell(
            onTap: onAtivos,
            borderRadius: BorderRadius.circular(12),
            child: OperationalMetricTile(
              label: 'Ativos',
              value: '$alunosAtivos',
              hint: alunosAtivos == 0
                  ? 'Sem movimento hoje'
                  : 'Base ativa',
              color: primary,
              isDark: isDark,
              semanticsLabel:
                  alunosAtivos == 0
                      ? '0 ativos, sem movimento hoje'
                      : '$alunosAtivos ativos',
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          InkWell(
            onTap: onCheckins,
            borderRadius: BorderRadius.circular(12),
            child: OperationalMetricTile(
              label: DashboardMicrocopy.checkinsPulseLabel,
              value: '$checkinsHoje',
              hint: checkinsHoje == 0
                  ? 'Sem movimento hoje'
                  : 'Check-ins de hoje',
              color: checkinsAccent,
              isDark: isDark,
              semanticsLabel:
                  checkinsHoje == 0
                      ? '0 check-ins, sem movimento hoje'
                      : '$checkinsHoje check-ins',
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          InkWell(
            onTap: onRisco,
            borderRadius: BorderRadius.circular(12),
            child: OperationalMetricTile(
              label: 'Risco',
              value: '$riscoAlto',
              hint: riscoAlto == 0
                  ? 'Sem movimento hoje'
                  : 'Alunos pedem contato',
              color: riscoAccent,
              isDark: isDark,
              emphasis: riscoAlto > 0
                  ? OperationalMetricEmphasis.alert
                  : OperationalMetricEmphasis.normal,
              semanticsLabel:
                  riscoAlto == 0
                      ? '0 em risco, sem movimento hoje'
                      : '$riscoAlto em risco',
            ),
          ),
          if (showTrendRow) ...[
            const SizedBox(height: TokensStrip.s2),
            _PulseTrendRow(
              isDark: isDark,
              primary: primary,
              hasTrend: hasTrend,
              trendReady: trendReady,
              hideEmptyTrend: hideEmptyTrend,
              checkinsHoje: checkinsHoje,
              checkinsTrend: checkinsTrend,
              emptyHint: emptyHint,
              comfortable: comfortable,
              trailingReserve: trailingReserve,
              onTap: onCheckins,
              showDivider: false,
            ),
          ],
          if (showCta) ...[
            const SizedBox(height: TokensStrip.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionChip(
                label: emptyTrendCtaLabel!,
                accent: primary,
                isDark: isDark,
                onPressed: onEmptyTrendCta!,
              ),
            ),
          ],
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
  final bool comfortable;
  final double trailingReserve;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final caption = dashboardReadableCaption(context, isDark: isDark);
    final hint = dashboardPulseEmptyHint(
      checkinsHoje: checkinsHoje,
      checkinsTrend: checkinsTrend,
      fromApi: emptyHint,
    );
    final emptyValue = hint ?? DashboardMicrocopy.tendenciaVaziaBase;
    final sparkW = comfortable ? 88.0 : 72.0;
    final sparkH = comfortable ? 24.0 : 20.0;

    return Semantics(
      button: true,
      label:
          !trendReady
              ? 'Tendência de check-ins carregando'
              : hasTrend
              ? 'Tendência de check-ins nos últimos 7 dias'
              : emptyValue,
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
                          child: Text(
                            DashboardMicrocopy.tendencia7Dias,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.cardTitle(
                              color: chrome.ink,
                            ),
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
                            emptyValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

