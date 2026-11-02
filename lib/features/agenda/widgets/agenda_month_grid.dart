import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_status.dart';

/// Mês: título grande, grade de borda a borda e a contagem de atendimentos.
/// Arrastar na horizontal troca o mês; o dia abre na visão Dia.
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

  /// Altura mínima da célula: a fonte da grade não escala (o leitor de tela
  /// lê o rótulo completo do dia).
  static const double cellHeight = 48;

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

    final grid = AnimatedSwitcher(
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
                        height: cellHeight,
                        onTap: () => onSelect(days[w * 7 + d]),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) => _swipe(d.primaryVelocity),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthTitle(
          month: month,
          onPrev: () => onSwipe(-1),
          onNext: () => onSwipe(1),
        ),
        body,
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
    required this.height,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final List<Agendamento> events;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final weekend = day.weekday >= DateTime.saturday;
    final Color fundo;
    final Color numero;
    if (selected) {
      fundo = primary;
      numero = fxPaletaSobreMarca(context).ink;
    } else {
      fundo = Colors.transparent;
      numero =
          isToday
              ? primary
              : !inMonth
              ? chrome.mute.withValues(alpha: 0.55)
              : weekend
              ? chrome.mute
              : chrome.ink;
    }

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
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fundo,
                    shape: BoxShape.circle,
                    border:
                        isToday && !selected
                            ? Border.all(color: primary, width: 1.5)
                            : null,
                  ),
                  child: Text(
                    '${day.day}',
                    style: FocuxHubTypography.body(color: numero).copyWith(
                      fontSize: 14,
                      fontWeight:
                          isToday || selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                _PontosDoDia(
                  events: events,
                  inMonth: inMonth,
                  isDark: chrome.isDark,
                  primary: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Até 3 pontos, com a cor do status; o resto vira "+N".
class _PontosDoDia extends StatelessWidget {
  const _PontosDoDia({
    required this.events,
    required this.inMonth,
    required this.isDark,
    required this.primary,
  });

  final List<Agendamento> events;
  final bool inMonth;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    if (events.isEmpty) return const SizedBox(height: 8);
    final pontos = events.take(3);
    final extra = events.length - pontos.length;
    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final e in pontos)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: agendaStatusColor(
                  e.naoVouEm != null ? 'FALTA' : e.status,
                  isDark: isDark,
                  primary: primary,
                ).withValues(alpha: inMonth ? 1 : 0.45),
              ),
            ),
          if (extra > 0)
            Text(
              '+$extra',
              style: FocuxHubTypography.chip(chrome.mute).copyWith(fontSize: 9, height: 1),
            ),
        ],
      ),
    );
  }
}
