import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
/// Display-only operational metrics live in `OperationalMetricTile` (core/widgets).
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
    this.emptyTrendCtaLabel,
    this.onEmptyTrendCta,
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
  final String? emptyTrendCtaLabel;
  final VoidCallback? onEmptyTrendCta;

  @override
  Widget build(BuildContext context) {
    final riscoAccent =
        riscoAlto > 0 ? EagleTokens.warn : TokensStrip.badgeSuccess;
    final tight = MediaQuery.sizeOf(context).width < 400;
    final gap = tight ? 6.0 : TokensStrip.s2;
    final neutralAccent = dashboardReadableCaption(context, isDark: isDark);

    return dashboardEntryMotion(
      context: context,
      fade: fade,
      slideBegin: const Offset(0, 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pulso operacional',
            style: dashboardSectionKickerStyle(context, isDark: isDark),
          ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: DashboardPulseChip(
                    icon: 'users',
                    value: alunosAtivos.toString(),
                    label: 'Ativos',
                    accent: neutralAccent,
                    isDark: isDark,
                    compact: tight,
                    onTap: onAtivos,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: DashboardPulseChip(
                    icon: 'circle-check',
                    value: checkinsHoje.toString(),
                    label: tight ? 'Checks' : 'Check-ins',
                    accent: pulseCheckinsAccent(
                      checkinsHoje: checkinsHoje,
                      neutralAccent: neutralAccent,
                    ),
                    isDark: isDark,
                    compact: tight,
                    onTap: onCheckins,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child:
                      hideRiscoChip
                          ? DashboardPulseChip(
                            icon: 'calendar',
                            value: agendaHoje.toString(),
                            label: tight ? 'Agenda' : 'Agenda hoje',
                            accent: neutralAccent,
                            isDark: isDark,
                            compact: tight,
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
                            compact: tight,
                            onTap: onRisco,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final mute = dashboardReadableMuted(context, isDark: isDark);
                final hasTrend = checkinsTrend.any((v) => v > 0);
                return Semantics(
                  label:
                      hasTrend
                          ? 'Tendência de check-ins nos últimos 7 dias'
                          : 'Sem check-ins nos últimos 7 dias',
                  child: InkWell(
                    onTap: onCheckins,
                    borderRadius: BorderRadius.circular(TokensStrip.rInput),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tendência 7 dias',
                                  style: dashboardSectionKickerStyle(
                                    context,
                                    isDark: isDark,
                                  ),
                                ),
                                if (!hasTrend) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sem check-ins nos últimos 7 dias',
                                    style: AppTypography.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: mute,
                                      height: 1.25,
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
                                neutralAccent: neutralAccent,
                              ),
                              width: 88,
                              height: 24,
                            )
                          else
                            Container(
                              width: 88,
                              height: 24,
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.timeline_rounded,
                                size: 20,
                                color: mute,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (showEmptyTrendCta &&
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
                      emptyTrendCtaLabel!.contains('treino')
                          ? Icons.fitness_center_rounded
                          : Icons.calendar_today_rounded,
                      size: 16,
                    ),
                    label: Text(
                      emptyTrendCtaLabel!,
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
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
    required this.compact,
    required this.onTap,
  });

  final String icon;
  final String value;
  final String label;
  final Color accent;
  final bool isDark;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final iconSize = compact ? 22.0 : 24.0;
    final iconGlyph = compact ? 11.0 : 12.0;
    final valueSize = compact ? 14.0 : 15.0;
    final labelSize = compact ? 9.5 : 10.0;
    final hPad = compact ? 7.0 : 9.0;

    return Semantics(
      button: true,
      label: '$value $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 9),
            decoration: fxStripCardDecoration(
              context,
              accent: accent,
              radius: TokensStrip.rCard,
              glowStrength: 0.14,
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
                            alpha: isDark ? 0.18 : 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(TokensStrip.rInput),
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
                          style: GoogleFonts.jetBrainsMono(
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
                    padding: EdgeInsets.only(left: iconSize + (compact ? 5 : 6)),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w600,
                        color: accent,
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
