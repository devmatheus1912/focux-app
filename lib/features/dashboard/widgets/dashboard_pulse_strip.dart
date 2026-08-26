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
      child: FxSettingsGroup(
        header: DashboardMicrocopy.pulsoOperacional,
        accent: primary,
        children: [
          FxSettingsTile(
            fxIcon: 'users',
            label: 'Ativos',
            value: '$alunosAtivos',
            numeric: true,
            showDivider: true,
            semanticsLabel:
                alunosAtivos == 0
                    ? '0 ativos, sem movimento hoje'
                    : '$alunosAtivos ativos',
            onTap: onAtivos,
          ),
          FxSettingsTile(
            fxIcon: 'circle-check',
            label: DashboardMicrocopy.checkinsPulseLabel,
            value: '$checkinsHoje',
            numeric: true,
            showDivider: true,
            accent: checkinsAccent,
            semanticsLabel:
                checkinsHoje == 0
                    ? '0 check-ins, sem movimento hoje'
                    : '$checkinsHoje check-ins',
            onTap: onCheckins,
          ),
          FxSettingsTile(
            fxIcon: riscoAlto > 0 ? 'alert-triangle' : 'circle-check',
            label: 'Risco',
            value: '$riscoAlto',
            numeric: true,
            showDivider: showTrendRow || showCta,
            accent: riscoAccent,
            semanticsLabel:
                riscoAlto == 0
                    ? '0 em risco, sem movimento hoje'
                    : '$riscoAlto em risco',
            onTap: onRisco,
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
              value: 'Abrir',
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

