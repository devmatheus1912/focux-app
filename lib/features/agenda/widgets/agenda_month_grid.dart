import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';

/// Calendário do mês estilo iOS: pontos por dia, arrastar troca o mês.
class AgendaMonthGrid extends StatelessWidget {
  const AgendaMonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.counts,
    required this.onSelect,
    required this.onSwipe,
    this.now,
  });

  static const double cellHeight = 40;

  final DateTime month;
  final DateTime selected;
  final Map<String, int> counts;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onSwipe;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final today = now ?? DateTime.now();
    final days = agendaMonthGrid(month);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: DecoratedBox(
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.03,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v.abs() < 250) return;
            HapticFeedback.selectionClick();
            onSwipe(v < 0 ? 1 : -1);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    for (final label in agendaWeekdayInitials)
                      Expanded(
                        child: ExcludeSemantics(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: FocuxHubTypography.chip(chrome.mute),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s1),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    key: ValueKey(agendaIsoDate(month)),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var w = 0; w < 6; w++)
                        Row(
                          children: [
                            for (var d = 0; d < 7; d++)
                              Expanded(
                                child: _MonthDayCell(
                                  day: days[w * 7 + d],
                                  inMonth: days[w * 7 + d].month == month.month,
                                  selected: agendaSameDay(
                                    days[w * 7 + d],
                                    selected,
                                  ),
                                  isToday: agendaSameDay(
                                    days[w * 7 + d],
                                    today,
                                  ),
                                  count:
                                      counts[agendaIsoDate(days[w * 7 + d])] ??
                                      0,
                                  onTap: () => onSelect(days[w * 7 + d]),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.count,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final Color numberColor;
    if (selected) {
      numberColor = Colors.white;
    } else if (isToday) {
      numberColor = primary;
    } else if (inMonth) {
      numberColor = chrome.ink;
    } else {
      numberColor = chrome.mute.withValues(alpha: 0.5);
    }
    final dots = count.clamp(0, 3);

    return Semantics(
      button: true,
      selected: selected,
      label: agendaMonthDayA11y(day: day, count: count, isToday: isToday),
      excludeSemantics: true,
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        radius: AgendaMonthGrid.cellHeight / 2,
        child: SizedBox(
          height: AgendaMonthGrid.cellHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border:
                      isToday && !selected
                          ? Border.all(color: primary.withValues(alpha: 0.6))
                          : null,
                ),
                child: Text(
                  '${day.day}',
                  style: FocuxHubTypography.body(color: numberColor).copyWith(
                    fontSize: 14,
                    fontWeight:
                        selected || isToday ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < dots; i++)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color:
                              inMonth
                                  ? primary
                                  : primary.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
