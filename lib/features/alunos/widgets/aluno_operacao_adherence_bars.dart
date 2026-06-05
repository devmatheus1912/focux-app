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
  });

  final List<AderenciaWeekPoint> points;
  final Color activeColor;
  final Color idleColor;

  static const _barMaxHeight = 34.0;
  static const _minFraction = 0.14;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxVal = points.fold<double>(
      1,
      (prev, p) => p.checkins > prev ? p.checkins : prev,
    );
    final labelColor = fxScreenMute(context);
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
                maxVal: maxVal,
                activeColor: activeColor,
                idleColor: idleColor,
                labelColor: labelColor,
                barMaxHeight: _barMaxHeight,
                labelBand: labelBand,
                minFraction: _minFraction,
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
    required this.maxVal,
    required this.activeColor,
    required this.idleColor,
    required this.labelColor,
    required this.barMaxHeight,
    required this.labelBand,
    required this.minFraction,
  });

  final double value;
  final String dayLabel;
  final double maxVal;
  final Color activeColor;
  final Color idleColor;
  final Color labelColor;
  final double barMaxHeight;
  final double labelBand;
  final double minFraction;

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

    return Semantics(
      label:
          dayLabel.isEmpty
              ? semanticsValue
              : '$dayLabel · $semanticsValue',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: barMaxHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: barMaxHeight * fraction,
                decoration: BoxDecoration(
                  color: hasActivity ? activeColor : idleColor,
                  borderRadius: BorderRadius.circular(4),
                ),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
