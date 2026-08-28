import 'package:flutter/material.dart';

import '../../../core/utils/a11y_announce.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../utils/aluno360_operacao_logic.dart';

/// Semana de check-ins — faixa compacta de 7 células (paridade Perfil inset).
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

  static const _cellHeight = 34.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final ink = fxScreenInk(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = fxScreenMute(context);
    final labelColor =
        emptyWeek
            ? Color.lerp(mute, ink, isDark ? 0.78 : 0.80)!
            : mute;

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
                labelColor: labelColor,
                emptyWeek: emptyWeek,
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
    required this.labelColor,
    required this.emptyWeek,
    required this.cellHeight,
  });

  final AderenciaWeekPoint point;
  final Color activeColor;
  final Color missColor;
  final Color todayRingColor;
  final Color labelColor;
  final bool emptyWeek;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final hasActivity = point.checkins > 0;
    final isToday = isIsoDateToday(point.date);
    final dayLabel = adherenceDayLetter(point);
    final semanticsValue = hasActivity ? 'Com check-in' : 'Sem registro';
    final weekday = weekdayNameFromIso(point.date);
    final tooltip =
        weekday.isEmpty
            ? semanticsValue
            : '$weekday · $semanticsValue${isToday ? ' · hoje' : ''}';

    final fill =
        hasActivity
            ? activeColor.withValues(alpha: 0.18)
            : missColor.withValues(alpha: emptyWeek ? 0.08 : 0.06);
    final borderColor =
        isToday
            ? todayRingColor
            : hasActivity
            ? activeColor.withValues(alpha: 0.42)
            : missColor.withValues(alpha: 0.28);
    final letterColor =
        isToday
            ? todayRingColor
            : hasActivity
            ? activeColor
            : labelColor;

    return Semantics(
      label:
          dayLabel.isEmpty
              ? semanticsValue
              : '$dayLabel · $semanticsValue${isToday ? ' · hoje' : ''}',
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => fxAnnounce(context, tooltip),
            child: AnimatedContainer(
              duration: Duration(milliseconds: fxMotionDurationMs(context)),
              curve: Curves.easeOutCubic,
              height: cellHeight,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasActivity)
                    Icon(Icons.check_rounded, size: 12, color: activeColor)
                  else
                    const SizedBox(height: 12),
                  const SizedBox(height: 2),
                  Text(
                    dayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Aluno360Layout.metaStyle(context).copyWith(
                      color: letterColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
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
