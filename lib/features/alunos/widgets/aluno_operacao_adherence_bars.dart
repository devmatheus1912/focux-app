import 'package:flutter/material.dart';

import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/aluno360_operacao_logic.dart';

/// Weekly check-in bars with D–S labels for the Operação status card.
class AlunoOperacaoAdherenceBars extends StatelessWidget {
  const AlunoOperacaoAdherenceBars({
    super.key,
    required this.points,
    required this.activeColor,
    required this.idleColor,
    this.emptyWeek = false,
  });

  final List<AderenciaWeekPoint> points;
  final Color activeColor;
  final Color idleColor;
  final bool emptyWeek;

  static const _barMaxHeight = 36.0;
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
            ? Color.lerp(fxScreenMute(context), ink, isDark ? 0.65 : 0.78)!
            : fxScreenMute(context);
    final labelBand =
        14.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

    return SizedBox(
      height: _barMaxHeight + labelBand,
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
                labelColor: labelColor,
                barMaxHeight: _barMaxHeight,
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
    required this.labelColor,
    required this.barMaxHeight,
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
  final Color labelColor;
  final double barMaxHeight;
  final double labelBand;
  final double minFraction;
  final bool outlineIdle;

  @override
  Widget build(BuildContext context) {
    final hasActivity = value > 0;
    final fraction =
        hasActivity
            ? (value / maxVal).clamp(minFraction, 1.0)
            : minFraction;
    final semanticsValue =
        hasActivity
            ? '${value.round()} check-in${value == 1 ? '' : 's'}'
            : 'Sem check-in';

    final weekday = weekdayNameFromIso(isoDate);
    final tooltip =
        weekday.isEmpty
            ? semanticsValue
            : '$weekday · $semanticsValue';

    return Semantics(
      label:
          dayLabel.isEmpty
              ? semanticsValue
              : '$dayLabel · $semanticsValue',
      button: true,
      child: Tooltip(
        message: tooltip,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: barMaxHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (outlineIdle && !hasActivity) ...[
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: labelColor.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      height: barMaxHeight * fraction,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            hasActivity
                                ? activeColor
                                : (outlineIdle
                                    ? Colors.transparent
                                    : idleColor),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            outlineIdle && !hasActivity
                                ? Border.all(
                                  color: idleColor.withValues(alpha: 0.85),
                                  width: 1,
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: labelBand,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: outlineIdle ? 10.5 : 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: outlineIdle ? 0.2 : 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
