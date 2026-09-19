import 'package:flutter/material.dart';

import '../../../core/utils/a11y_announce.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../utils/aluno360_operacao_logic.dart';

/// Semana de check-ins — 7 células com dia do mês + estado visual.
class AlunoOperacaoAdherenceBars extends StatelessWidget {
  const AlunoOperacaoAdherenceBars({
    super.key,
    required this.points,
    required this.activeColor,
    required this.missColor,
    required this.todayRingColor,
  });

  final List<AderenciaWeekPoint> points;
  final Color activeColor;
  final Color missColor;
  final Color todayRingColor;

  static const _cellHeight = 40.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: 'Check-ins dos últimos 7 dias',
      child: Row(
        children: [
          for (var i = 0; i < points.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(
              child: _AdherenceWeekCell(
                point: points[i],
                activeColor: activeColor,
                missColor: missColor,
                todayRingColor: todayRingColor,
                cellHeight: _cellHeight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdherenceWeekCell extends StatelessWidget {
  const _AdherenceWeekCell({
    required this.point,
    required this.activeColor,
    required this.missColor,
    required this.todayRingColor,
    required this.cellHeight,
  });

  final AderenciaWeekPoint point;
  final Color activeColor;
  final Color missColor;
  final Color todayRingColor;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final hasActivity = point.checkins > 0;
    final isToday = isIsoDateToday(point.date);
    final dayLabel = adherenceDayCellLabel(point);
    final weekday = weekdayNameFromIso(point.date);
    final semanticsValue = hasActivity ? 'Com check-in' : 'Sem registro';
    final tooltip =
        weekday.isEmpty
            ? semanticsValue
            : '$weekday · $semanticsValue${isToday ? ' · hoje' : ''}';

    // Sem check-in → missColor (legenda laranja), não idle cinza.
    final emptyFill = missColor.withValues(alpha: 0.14);
    final emptyBorder = missColor.withValues(alpha: 0.55);
    final fill =
        hasActivity
            ? activeColor.withValues(alpha: 0.18)
            : emptyFill;
    final borderColor =
        isToday
            ? todayRingColor
            : hasActivity
            ? activeColor.withValues(alpha: 0.42)
            : emptyBorder;
    final numberColor =
        isToday
            ? todayRingColor
            : hasActivity
            ? activeColor
            : missColor;

    return Semantics(
      label:
          weekday.isEmpty
              ? semanticsValue
              : '$weekday · $semanticsValue${isToday ? ' · hoje' : ''}',
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => fxAnnounce(context, tooltip),
            child: AnimatedContainer(
              duration: Duration(milliseconds: fxMotionDurationMs(context)),
              curve: Curves.easeOutCubic,
              height: cellHeight,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasActivity)
                    Icon(Icons.check_rounded, size: 13, color: activeColor)
                  else
                    const SizedBox(height: 13),
                  const SizedBox(height: 3),
                  Text(
                    dayLabel,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: Aluno360Layout.metaStyle(context).copyWith(
                      color: numberColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 1,
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
