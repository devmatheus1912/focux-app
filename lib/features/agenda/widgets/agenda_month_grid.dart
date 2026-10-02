import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';

/// Mês no formato do Calendário do iPhone: título grande, grade de borda a
/// borda com hairline por semana e até dois atendimentos por dia.
/// Arrastar (vertical ou horizontal) troca o mês.
class AgendaMonthGrid extends StatelessWidget {
  const AgendaMonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.eventsByDay,
    required this.onSelect,
    required this.onSwipe,
    this.now,
  });

  /// Célula de altura fixa: a fonte da grade não escala (o leitor de tela
  /// lê o rótulo completo do dia).
  static const double cellHeight = 66;
  static const int maxChips = 2;

  final DateTime month;
  final DateTime selected;
  final Map<String, List<Agendamento>> eventsByDay;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onSwipe;
  final DateTime? now;

  void _swipe(double? velocity) {
    final v = velocity ?? 0;
    if (v.abs() < 250) return;
    HapticFeedback.selectionClick();
    onSwipe(v < 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final today = now ?? DateTime.now();
    final days = agendaMonthGrid(month);
    final weeks = agendaMonthWeeks(month);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthTitle(
          month: month,
          onPrev: () => onSwipe(-1),
          onNext: () => onSwipe(1),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (d) => _swipe(d.primaryVelocity),
          onHorizontalDragEnd: (d) => _swipe(d.primaryVelocity),
          child: MediaQuery.withNoTextScaling(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensStrip.s1),
                  child: Row(
                    children: [
                      for (final (i, label) in agendaWeekdayInitials.indexed)
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.chip(
                                i >= 5
                                    ? chrome.mute.withValues(alpha: 0.6)
                                    : chrome.mute,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: fxMotionDuration(
                    context,
                    normal: const Duration(milliseconds: 180),
                  ),
                  child: Column(
                    key: ValueKey(agendaIsoDate(month)),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var w = 0; w < weeks; w++)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: chrome.line, width: 0.5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var d = 0; d < 7; d++)
                                Expanded(
                                  child: _MonthDayCell(
                                    day: days[w * 7 + d],
                                    inMonth:
                                        days[w * 7 + d].month == month.month,
                                    selected: agendaSameDay(
                                      days[w * 7 + d],
                                      selected,
                                    ),
                                    isToday: agendaSameDay(
                                      days[w * 7 + d],
                                      today,
                                    ),
                                    events:
                                        eventsByDay[agendaIsoDate(
                                          days[w * 7 + d],
                                        )] ??
                                        const [],
                                    onTap: () => onSelect(days[w * 7 + d]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthTitle extends StatelessWidget {
  const _MonthTitle({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    Widget seta(IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(
          tooltip: tooltip,
          onPressed: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          constraints: const BoxConstraints(
            minWidth: FxHomeSheetChrome.touchTarget,
            minHeight: FxHomeSheetChrome.touchTarget,
          ),
          icon: Icon(icon, color: primary),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s1,
        TokensStrip.s1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              liveRegion: true,
              label: agendaMonthLabel(month),
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: agendaMonthNames[month.month]),
                    TextSpan(
                      text: ' ${month.year}',
                      style: TextStyle(
                        color: chrome.mute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.pageTitle(
                  context,
                  color: chrome.ink,
                ).copyWith(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          seta(Icons.chevron_left_rounded, 'Mês anterior', onPrev),
          seta(Icons.chevron_right_rounded, 'Próximo mês', onNext),
        ],
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
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final List<Agendamento> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final weekend = day.weekday >= DateTime.saturday;
    final Color circle;
    final Color numberColor;
    if (isToday) {
      circle = primary;
      numberColor = Colors.white;
    } else if (selected) {
      circle = chrome.ink;
      numberColor = chrome.isDark ? Colors.black : Colors.white;
    } else {
      circle = Colors.transparent;
      numberColor =
          !inMonth
              ? chrome.mute.withValues(alpha: 0.4)
              : weekend
              ? chrome.mute
              : chrome.ink;
    }
    final chips = events.take(AgendaMonthGrid.maxChips).toList();
    final extra = events.length - chips.length;

    return Semantics(
      button: true,
      selected: selected,
      label: agendaMonthDayA11y(
        day: day,
        count: events.length,
        isToday: isToday,
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          height: AgendaMonthGrid.cellHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1.5, 3, 1.5, 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: fxMotionDuration(
                    context,
                    normal: const Duration(milliseconds: 160),
                  ),
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: circle,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: FocuxHubTypography.body(color: numberColor).copyWith(
                      fontSize: 14,
                      fontWeight:
                          isToday || selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                for (final ag in chips)
                  _EventChip(
                    label: agendaChipLabel(ag),
                    color: primary,
                    faded: !inMonth,
                  ),
                if (extra > 0)
                  Text(
                    '+$extra',
                    maxLines: 1,
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 9, height: 1.1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.label,
    required this.color,
    required this.faded,
  });

  final String label;
  final Color color;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final ink = ShellChrome.of(context).ink;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: faded ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: FocuxHubTypography.body(
          color: faded ? ink.withValues(alpha: 0.5) : ink,
        ).copyWith(fontSize: 9, height: 1.15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
