import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';

/// Mês no formato do Calendário do iPhone: título grande, grade de borda a
/// borda com hairline por semana e atendimentos em chips.
/// Arrastar (vertical ou horizontal) troca o mês.
///
/// Com [expand], as semanas dividem a altura disponível e cada dia mostra
/// quantos chips couberem (mínimo [maxChips]).
class AgendaMonthGrid extends StatelessWidget {
  const AgendaMonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.eventsByDay,
    required this.onSelect,
    required this.onSwipe,
    this.onToday,
    this.expand = false,
    this.now,
  });

  /// Altura mínima da célula: a fonte da grade não escala (o leitor de tela
  /// lê o rótulo completo do dia).
  static const double cellHeight = 66;
  static const int maxChips = 2;
  static const int _maxChipsExpanded = 5;
  static const double _chipSlot = 13;
  static const double _cellChrome = 3 + 24 + 2 + 11;

  final DateTime month;
  final DateTime selected;
  final Map<String, List<Agendamento>> eventsByDay;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onSwipe;

  /// Botão "Hoje" na linha do título; nulo esconde.
  final VoidCallback? onToday;
  final bool expand;
  final DateTime? now;

  static int chipsFor(double height) {
    final fit = ((height - _cellChrome) / _chipSlot).floor();
    return fit.clamp(maxChips, _maxChipsExpanded);
  }

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

    Widget weekRows(double height, int chips) => AnimatedSwitcher(
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
                border: Border(top: BorderSide(color: chrome.line, width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: _MonthDayCell(
                        day: days[w * 7 + d],
                        inMonth: days[w * 7 + d].month == month.month,
                        selected: agendaSameDay(days[w * 7 + d], selected),
                        isToday: agendaSameDay(days[w * 7 + d], today),
                        events:
                            eventsByDay[agendaIsoDate(days[w * 7 + d])] ??
                            const [],
                        height: height,
                        maxChips: chips,
                        onTap: () => onSelect(days[w * 7 + d]),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    final grid =
        expand
            ? Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h =
                      constraints.maxHeight.isFinite
                          ? (constraints.maxHeight / weeks).floorToDouble()
                          : cellHeight;
                  final height = h < cellHeight ? cellHeight : h;
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: weekRows(height, chipsFor(height)),
                  );
                },
              ),
            )
            : weekRows(cellHeight, maxChips);

    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (d) => _swipe(d.primaryVelocity),
      onHorizontalDragEnd: (d) => _swipe(d.primaryVelocity),
      child: MediaQuery.withNoTextScaling(
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            grid,
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthTitle(
          month: month,
          onPrev: () => onSwipe(-1),
          onNext: () => onSwipe(1),
          onToday: onToday,
        ),
        if (expand) Expanded(child: body) else body,
      ],
    );
  }
}

class _MonthTitle extends StatelessWidget {
  const _MonthTitle({
    required this.month,
    required this.onPrev,
    required this.onNext,
    this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onToday;

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
          if (onToday != null)
            Tooltip(
              message: S.of(context).agendaIrParaHoje,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onToday!();
                },
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  minimumSize: const Size(
                    FxHomeSheetChrome.touchTarget,
                    FxHomeSheetChrome.touchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensStrip.s2,
                  ),
                ),
                child: Text(
                  S.of(context).agendaHoje,
                  style: FocuxHubTypography.body(
                    color: primary,
                  ).copyWith(fontWeight: FontWeight.w700),
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
    required this.height,
    required this.maxChips,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final List<Agendamento> events;
  final double height;
  final int maxChips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final weekend = day.weekday >= DateTime.saturday;
    final Color circle;
    final Color numberColor;
    if (selected) {
      circle = isToday ? primary : chrome.ink;
      numberColor = isToday || !chrome.isDark ? Colors.white : Colors.black;
    } else if (isToday) {
      circle = Colors.transparent;
      numberColor = primary;
    } else {
      circle = Colors.transparent;
      numberColor =
          !inMonth
              ? chrome.mute.withValues(alpha: 0.4)
              : weekend
              ? chrome.mute
              : chrome.ink;
    }
    final chips = events.take(maxChips).toList();
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
          height: height,
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
