import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/alunos/data/aluno_contact_utils.dart';
import '../../../features/alunos/data/aluno_repository.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../data/agenda_novo_args.dart';
import '../data/agenda_repository.dart';
import '../providers/agenda_provider.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_slots.dart';
import '../utils/agenda_status.dart';
import '../utils/agenda_month.dart';
import '../widgets/agenda_day_sheet.dart';
import '../widgets/agenda_month_grid.dart';
import '../widgets/agenda_help_sheet.dart';
import '../widgets/agenda_hub_header.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/constants/dashboard_layout.dart';
import '../widgets/agenda_slot_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';

part 'agenda_screen_actions.part.dart';
part 'agenda_screen_widgets.part.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});
  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  List<Agendamento> _ags = [];
  final _agsLive = ValueNotifier<List<Agendamento>>(const []);
  Object? _erro;
  DateTime? _fetchedAt;
  late DateTime _mes;
  late DateTime _dia;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mes = agendaMonthOf(now);
    _dia = agendaDefaultSelectedDay(_mes, now: now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.track(ProductEvents.agendaViewed);
    });
    _load();
  }

  @override
  void dispose() {
    _agsLive.dispose();
    super.dispose();
  }

  void _setAgs(List<Agendamento> items) {
    _ags = items;
    _agsLive.value = items;
  }

  Future<void> _load({bool force = false}) async {
    final keepStale = _ags.isNotEmpty;
    final mes = _mes;
    final cacheKey = 'mes:${agendaIsoDate(mes)}';
    try {
      if (force) invalidateAgendaCaches(ref);
      final cached = force ? null : AgendaWeekClientCache.get(cacheKey);
      if (cached != null) {
        setState(() {
          _setAgs(cached);
          _erro = null;
          _fetchedAt = DateTime.now();
        });
        return;
      }
      if (!keepStale && _erro != null) setState(() => _erro = null);
      final items = await ref
          .read(agendaRepositoryProvider)
          .listarMes(mes.year, mes.month);
      AgendaWeekClientCache.put(cacheKey, items);
      if (!mounted || mes != _mes) return;
      setState(() {
        _setAgs(items);
        _erro = null;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted || mes != _mes) return;
      if (keepStale) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível atualizar a agenda.'),
        );
      } else {
        setState(() => _erro = e);
      }
    }
  }

  /// Dia passado não agenda: o "+" cai em hoje.
  Future<void> _novoAgendamento({
    DateTime? day,
    DateTime? slot,
    int? duracaoMin,
  }) async {
    var target = slot ?? day ?? _dia;
    if (agendaDayIsPast(target)) target = agendaDayStart(DateTime.now());
    final args = AgendaNovoArgs(
      day: target,
      inicio: slot,
      duracaoMin: duracaoMin,
      agendamentos: agendaMonthOf(target) == _mes ? _ags : null,
    );
    await context.push('/agenda/novo', extra: args);
    if (!mounted) return;
    _load(force: true);
  }

  Future<List<Agendamento>> _loadMonth(DateTime month) {
    if (month == _mes && _ags.isNotEmpty) return Future.value(_ags);
    return ref
        .read(agendaRepositoryProvider)
        .listarMes(month.year, month.month);
  }

  bool get _isTodayVisible => agendaSameDay(_dia, DateTime.now());

  void _selectDay(DateTime day) {
    final mes = agendaMonthOf(day);
    final mudouMes = mes != _mes;
    setState(() {
      _dia = day;
      if (mudouMes) {
        _mes = mes;
        _setAgs(const []);
      }
    });
    if (mudouMes) _load();
  }

  Future<void> _openDay(DateTime day) async {
    _selectDay(day);
    await showFxHomeSheet<void>(
      context,
      builder:
          (_) => AgendaDaySheet(
            day: day,
            agendamentos: _agsLive,
            photoFor: _photoFor,
            onRefresh: () {
              AnalyticsService.instance.track(ProductEvents.agendaRefreshed);
              return _load(force: true);
            },
            onOpen: (ag) {
              _popRootOverlay();
              _openAgendamentoDetails(ag);
            },
            onNew: (slot, duracaoMin) {
              _popRootOverlay();
              _novoAgendamento(day: day, slot: slot, duracaoMin: duracaoMin);
            },
          ),
    );
  }

  void _goToday() =>
      _selectDay(agendaDefaultSelectedDay(agendaMonthOf(DateTime.now())));

  void _changeMonth(int delta) =>
      _selectDay(agendaDefaultSelectedDay(agendaShiftMonth(_mes, delta)));

  String? _photoFor(int alunoId) {
    final list = ref.read(alunosProvider).value;
    if (list == null) return null;
    for (final aluno in list) {
      if (aluno.id == alunoId) return aluno.fotoUrl;
    }
    return null;
  }

  Aluno? _alunoFromCache(int alunoId) {
    final list = ref.read(alunosProvider).value;
    if (list == null) return null;
    for (final aluno in list) {
      if (aluno.id == alunoId) return aluno;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final showError = _erro != null && _ags.isEmpty;
    return fxScreenA11yScope(
      label: 'Agenda',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        extendBody: true,
        safeArea: false,
        body: SafeArea(
          bottom: false,
          child: FxContentWidthLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AgendaHubHeader(
                  freshnessLabel: freshnessLabel,
                  onHelp: () {
                    AnalyticsService.instance.track(
                      ProductEvents.agendaHelpOpened,
                    );
                    showAgendaHelpSheet(context);
                  },
                  onIcal: _copyIcalLink,
                  onNew: () => _novoAgendamento(),
                ),
                Expanded(
                  child:
                      showError
                          ? FxErrorState(
                            chromeOnDark: chrome.isDark,
                            primary: primary,
                            message: friendlyError(_erro!),
                            onRetry: () => _load(force: true),
                          )
                          : Padding(
                            padding: const EdgeInsets.only(
                              bottom: DashboardLayout.bottomDockClearance,
                            ),
                            child: AgendaMonthGrid(
                              month: _mes,
                              selected: _dia,
                              eventsByDay: agendaVisibleByDay(_ags),
                              onSelect: _openDay,
                              onSwipe: _changeMonth,
                              onToday: _isTodayVisible ? null : _goToday,
                              expand: true,
                            ),
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
