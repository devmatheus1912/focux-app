import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_slots.dart';

class AgendaSlotPick {
  const AgendaSlotPick({required this.inicio, required this.duracaoMin});

  final DateTime inicio;
  final int duracaoMin;

  DateTime get fim => inicio.add(Duration(minutes: duracaoMin));
}

typedef AgendaMonthLoader = Future<List<Agendamento>> Function(DateTime month);

Future<AgendaSlotPick?> showAgendaSlotPicker(
  BuildContext context, {
  required String title,
  required DateTime day,
  DateTime? inicio,
  int duracaoMin = agendaDuracaoPadraoMin,
  List<Agendamento>? agendamentos,
  AgendaMonthLoader? loadMonth,
  int? excludeId,
  String? aviso,
}) {
  return showFxHomeSheet<AgendaSlotPick>(
    context,
    builder:
        (_) => AgendaSlotPickerSheet(
          title: title,
          day: day,
          inicio: inicio,
          duracaoMin: duracaoMin,
          agendamentos: agendamentos,
          loadMonth: loadMonth,
          excludeId: excludeId,
          aviso: aviso,
        ),
  );
}

/// Horário dentro de um dia: grade de 30 min com ocupados marcados pelo nome
/// do aluno e a duração em chips. Outro dia só por "Trocar dia".
class AgendaSlotPickerSheet extends StatefulWidget {
  const AgendaSlotPickerSheet({
    super.key,
    required this.title,
    required this.day,
    this.inicio,
    this.duracaoMin = agendaDuracaoPadraoMin,
    this.agendamentos,
    this.loadMonth,
    this.excludeId,
    this.aviso,
    this.now,
  });

  final String title;
  final DateTime day;
  final DateTime? inicio;
  final int duracaoMin;

  /// Mês de [day] já carregado; nulo faz a sheet buscar via [loadMonth].
  final List<Agendamento>? agendamentos;
  final AgendaMonthLoader? loadMonth;

  /// Horário em remarcação: não ocupa a própria grade.
  final int? excludeId;

  /// Motivo da recusa anterior; snackbar ficaria atrás da sheet.
  final String? aviso;
  final DateTime? now;

  @override
  State<AgendaSlotPickerSheet> createState() => _AgendaSlotPickerSheetState();
}

class _AgendaSlotPickerSheetState extends State<AgendaSlotPickerSheet> {
  final _events = <int, Agendamento>{};
  final _loadedMonths = <DateTime>{};
  late DateTime _day;
  late DateTime _calMonth;
  late int _duracao;
  late final List<int> _duracoes;
  DateTime? _inicio;
  var _choosingDay = false;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final today = agendaDayStart(_now);
    final seed = agendaDayStart(widget.day);
    _day = seed.isBefore(today) ? today : seed;
    _calMonth = agendaMonthOf(_day);
    _duracao = widget.duracaoMin;
    _duracoes = agendaDuracoesCom(_duracao);
    final preloaded = widget.agendamentos;
    if (preloaded != null) {
      for (final ag in preloaded) {
        _events[ag.id] = ag;
      }
      _loadedMonths.add(agendaMonthOf(seed));
    }
    final wanted = widget.inicio;
    _inicio =
        wanted != null && agendaSameDay(wanted, _day) && _slotFree(wanted)
            ? wanted
            : _defaultSlot();
    _ensureMonth(_day);
  }

  Iterable<Agendamento> get _dayEvents =>
      _events.values.where((ag) => agendaSameDay(ag.inicio, _day));

  Agendamento? _conflict(DateTime slot) => agendaSlotConflict(
    slot,
    _duracao,
    _dayEvents,
    excludeId: widget.excludeId,
  );

  bool _slotFree(DateTime slot) =>
      !agendaDateTimeIsInPast(slot, now: _now) &&
      agendaSlotFitsDay(slot, _duracao) &&
      _conflict(slot) == null &&
      agendaSlotsDoDia(_day).contains(slot);

  DateTime? _defaultSlot() {
    final def = agendaDefaultSlot(_day, now: _now);
    return _slotFree(def) ? def : null;
  }

  DateTime? _keepTime(DateTime? previous) {
    if (previous == null) return _defaultSlot();
    final moved = DateTime(
      _day.year,
      _day.month,
      _day.day,
      previous.hour,
      previous.minute,
    );
    return _slotFree(moved) ? moved : _defaultSlot();
  }

  Future<void> _ensureMonth(DateTime day) async {
    final loader = widget.loadMonth;
    final month = agendaMonthOf(day);
    if (loader == null || _loadedMonths.contains(month)) return;
    _loadedMonths.add(month);
    final List<Agendamento> items;
    try {
      items = await loader(month);
    } catch (_) {
      _loadedMonths.remove(month);
      return;
    }
    if (!mounted) return;
    setState(() {
      _events.removeWhere((_, ag) => agendaMonthOf(ag.inicio) == month);
      for (final ag in items) {
        _events[ag.id] = ag;
      }
      final current = _inicio;
      if (current != null && !_slotFree(current)) _inicio = null;
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _day = day;
      _choosingDay = false;
      _inicio = _keepTime(_inicio);
    });
    _ensureMonth(day);
  }

  void _selectDuracao(int minutos) {
    setState(() {
      _duracao = minutos;
      final current = _inicio;
      if (current != null && !_slotFree(current)) _inicio = null;
    });
  }

  void _confirm() {
    final inicio = _inicio;
    if (inicio == null) return;
    if (!_slotFree(inicio)) {
      setState(() => _inicio = null);
      return;
    }
    Navigator.pop(
      context,
      AgendaSlotPick(inicio: inicio, duracaoMin: _duracao),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final dayLabel = agendaDayShortLabel(_day);
    final inicio = _inicio;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '${widget.title}, $dayLabel',
      child: FxHomeSheetSurface(
        isDark: chrome.isDark,
        expand: true,
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              title: dayLabel[0].toUpperCase() + dayLabel.substring(1),
              subtitle: widget.title,
              leading: Icon(Icons.schedule_outlined, color: primary, size: 18),
              trailing: TextButton(
                onPressed:
                    () => setState(() {
                      _choosingDay = !_choosingDay;
                      _calMonth = agendaMonthOf(_day);
                    }),
                child: Text(s.agendaTrocarDia),
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            if (widget.aviso case final aviso?) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  aviso,
                  style: FocuxHubTypography.bodyMuted(
                    color: EagleTokens.semanticBad(isDark: chrome.isDark),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s2),
            ],
            if (_choosingDay)
              Expanded(child: _buildMonth(s, chrome, primary))
            else ...[
              Text(
                s.agendaDuracao,
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TokensStrip.s2),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final d in _duracoes)
                    FxToggleChip(
                      label: agendaDuracaoLabel(d),
                      selected: d == _duracao,
                      isDark: chrome.isDark,
                      onTap: () => _selectDuracao(d),
                    ),
                ],
              ),
              SizedBox(height: TokensStrip.s3),
              Expanded(child: _buildSlots(s, chrome, primary)),
            ],
            Divider(height: 1, color: chrome.line.withValues(alpha: 0.8)),
            SizedBox(height: TokensStrip.s3),
            FxLiquidPrimaryButton(
              label:
                  inicio == null
                      ? s.agendaEscolhaHorario
                      : '${agendaHorarioConfirmLabel()} · ${agendaHm(inicio)}–${agendaHm(inicio.add(Duration(minutes: _duracao)))}',
              onPressed: inicio == null || _choosingDay ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlots(S s, ShellPalette chrome, Color primary) {
    final now = _now;
    final slots =
        agendaSlotsDoDia(
          _day,
        ).where((slot) => !agendaDateTimeIsInPast(slot, now: now)).toList();
    if (slots.isEmpty) {
      return Center(
        child: Text(
          s.agendaSemHorariosLivres,
          textAlign: TextAlign.center,
          style: FocuxHubTypography.bodyMuted(
            color: chrome.mute,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return GridView.builder(
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (_, index) {
        final slot = slots[index];
        final conflict = _conflict(slot);
        final enabled = conflict == null && agendaSlotFitsDay(slot, _duracao);
        final selected = slot == _inicio;
        final hm = agendaHm(slot);
        final ocupante =
            conflict == null ? null : agendaPrimeiroNome(conflict.alunoNome);
        return Semantics(
          button: enabled,
          selected: selected,
          enabled: enabled,
          label:
              ocupante == null
                  ? 'Horário $hm'
                  : 'Horário $hm, ocupado por $ocupante',
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  enabled
                      ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _inicio = slot);
                      }
                      : null,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  color:
                      selected
                          ? primary
                          : chrome.cardFill.withValues(
                            alpha: enabled ? 1 : 0.45,
                          ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        selected
                            ? primary
                            : chrome.lineStrong.withValues(
                              alpha: enabled ? 1 : 0.4,
                            ),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hm,
                      style: FocuxHubTypography.cardTitle(
                        color:
                            selected
                                ? onPrimary
                                : chrome.ink.withValues(
                                  alpha: enabled ? 1 : 0.35,
                                ),
                      ).copyWith(
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (ocupante != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ocupante,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonth(S s, ShellPalette chrome, Color primary) {
    final today = agendaDayStart(_now);
    final canGoBack = _calMonth.isAfter(agendaMonthOf(today));
    final days = agendaMonthGrid(_calMonth);
    final weeks = agendaMonthWeeks(_calMonth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: s.agendaMesAnterior,
              onPressed:
                  canGoBack
                      ? () => setState(
                        () => _calMonth = agendaShiftMonth(_calMonth, -1),
                      )
                      : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                agendaMonthLabel(_calMonth),
                textAlign: TextAlign.center,
                style: FocuxHubTypography.cardTitle(color: chrome.ink),
              ),
            ),
            IconButton(
              tooltip: s.agendaProximoMes,
              onPressed:
                  () => setState(
                    () => _calMonth = agendaShiftMonth(_calMonth, 1),
                  ),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Row(
          children: [
            for (final initial in agendaWeekdayInitials)
              Expanded(
                child: Text(
                  initial,
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.bodyMuted(
                    color: chrome.mute,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: TokensStrip.s2),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final day in days.take(weeks * 7))
                if (day.month != _calMonth.month)
                  const SizedBox.shrink()
                else
                  _MonthDayCell(
                    day: day,
                    selected: agendaSameDay(day, _day),
                    isToday: agendaSameDay(day, today),
                    enabled: !day.isBefore(today),
                    onTap: () => _selectDay(day),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: selected,
      label: agendaMonthDayA11y(day: day, count: 0, isToday: isToday),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              enabled
                  ? () {
                    HapticFeedback.selectionClick();
                    onTap();
                  }
                  : null,
          customBorder: const CircleBorder(),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? primary : Colors.transparent,
              border:
                  isToday && !selected
                      ? Border.all(color: primary.withValues(alpha: 0.6))
                      : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: FocuxHubTypography.cardTitle(
                  color:
                      selected
                          ? onPrimary
                          : chrome.ink.withValues(alpha: enabled ? 1 : 0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
