import 'package:flutter/material.dart';

import '../../../core/utils/a11y_announce.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../utils/aluno360_operacao_logic.dart';

/// Weekly check-in bars with D–S labels for the Operação status card.
class AlunoOperacaoAdherenceBars extends StatelessWidget {
  const AlunoOperacaoAdherenceBars({
    super.key,
    required this.points,
    required this.activeColor,
    required this.idleColor,
    required this.missColor,
    required this.todayRingColor,
    this.emptyWeek = false,
  });

  final List<AderenciaWeekPoint> points;
  final Color activeColor;
  final Color idleColor;
  final Color missColor;
  final Color todayRingColor;
  final bool emptyWeek;

  static const _barMaxHeight = 36.0;
  static const _markerBand = 14.0;
  static const _minFraction = 0.14;
  static const _emptyWeekMinFraction = 0.14;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxVal = points.fold<double>(
      1,
      (prev, p) => p.checkins > prev ? p.checkins : prev,
    );
    final ink = fxScreenInk(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        emptyWeek
            ? Color.lerp(fxScreenMute(context), ink, isDark ? 0.78 : 0.80)!
            : fxScreenMute(context);
    final labelBand =
        14.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

    final markerBand = emptyWeek ? _markerBand : 0.0;
    return SizedBox(
      height: _barMaxHeight + markerBand + labelBand,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: _AdherenceDayBar(
                value: points[i].checkins,
                dayLabel: weekdayLetterFromIso(points[i].date),
                isoDate: points[i].date,
                maxVal: maxVal,
                activeColor: activeColor,
                idleColor: idleColor,
                missColor: missColor,
                todayRingColor: todayRingColor,
                labelColor: labelColor,
                barMaxHeight: _barMaxHeight,
                markerBand: markerBand,
                labelBand: labelBand,
                minFraction: emptyWeek ? _emptyWeekMinFraction : _minFraction,
                outlineIdle: emptyWeek,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdherenceDayBar extends StatelessWidget {
  const _AdherenceDayBar({
    required this.value,
    required this.dayLabel,
    required this.isoDate,
    required this.maxVal,
    required this.activeColor,
    required this.idleColor,
    required this.missColor,
    required this.todayRingColor,
    required this.labelColor,
    required this.barMaxHeight,
    required this.markerBand,
    required this.labelBand,
    required this.minFraction,
    this.outlineIdle = false,
  });

  final double value;
  final String dayLabel;
  final String? isoDate;
  final double maxVal;
  final Color activeColor;
  final Color idleColor;
  final Color missColor;
  final Color todayRingColor;
  final Color labelColor;
  final double barMaxHeight;
  final double markerBand;
  final double labelBand;
  final double minFraction;
  final bool outlineIdle;

  @override
  Widget build(BuildContext context) {
    final hasActivity = value > 0;
    final isToday = isIsoDateToday(isoDate);
    final fraction =
        hasActivity
            ? (value / maxVal).clamp(minFraction, 1.0)
            : minFraction;
    final semanticsValue =
        hasActivity
            ? '${value.round()} registro${value == 1 ? '' : 's'}'
            : 'Sem registro';

    final weekday = weekdayNameFromIso(isoDate);
    final tooltip =
        weekday.isEmpty
            ? semanticsValue
            : '$weekday · $semanticsValue${isToday ? ' · hoje' : ''}';

    final barFill =
        hasActivity
            ? activeColor
            : (outlineIdle
                ? Colors.transparent
                : missColor.withValues(alpha: 0.38));
    final barBorder =
        outlineIdle && !hasActivity
            ? Border.all(color: missColor.withValues(alpha: 0.65), width: 1.5)
            : hasActivity
            ? Border.all(color: activeColor.withValues(alpha: 0.35), width: 1)
            : null;

    return Semantics(
      label:
          dayLabel.isEmpty
              ? semanticsValue
              : '$dayLabel · $semanticsValue${isToday ? ' · hoje' : ''}',
      hint: 'Ouvir detalhes do dia',
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => fxAnnounce(context, tooltip),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: barMaxHeight + markerBand,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (markerBand > 0 && outlineIdle && !hasActivity)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: missColor.withValues(alpha: 0.92),
                                  width: 2,
                                ),
                              ),
                            )
                          else if (markerBand > 0 && hasActivity)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 7,
                                color: Colors.white.withValues(alpha: 0.96),
                              ),
                            ),
                          AnimatedContainer(
                            duration: Duration(
                              milliseconds:
                                  fxMotionDurationMs(context),
                            ),
                            curve: Curves.easeOutCubic,
                            height: barMaxHeight * fraction,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: barFill,
                              borderRadius: BorderRadius.circular(4),
                              border: barBorder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: labelBand,
                    child: Center(
                      child: DecoratedBox(
                        decoration:
                            isToday
                                ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: todayRingColor,
                                    width: 1.5,
                                  ),
                                )
                                : const BoxDecoration(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isToday ? 4 : 0,
                            vertical: isToday ? 1 : 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              dayLabel,
                              style: Aluno360Layout.metaStyle(context).copyWith(
                                color: isToday ? todayRingColor : labelColor,
                                letterSpacing: outlineIdle ? 0.2 : 0,
                              ),
                            ),
                          ),
                        ),
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
