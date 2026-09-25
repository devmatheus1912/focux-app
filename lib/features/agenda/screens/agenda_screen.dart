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
import '../data/agenda_repository.dart';
import '../providers/agenda_provider.dart';
import '../utils/agenda_day_lane.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_status.dart';
import '../widgets/agenda_day_empty_panel.dart';
import '../widgets/agenda_day_chip.dart';
import '../widgets/agenda_event_card.dart';
import '../widgets/agenda_help_sheet.dart';
import '../widgets/agenda_hub_header.dart';
import '../widgets/agenda_next_banner.dart';
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
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/constants/dashboard_layout.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../widgets/agenda_form_sheets.dart';

part 'agenda_screen_actions.part.dart';
part 'agenda_screen_widgets.part.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});
  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  List<Agendamento> _ags = [];
  bool _loading = true;
  Object? _erro;
  DateTime? _fetchedAt;
  int _selectedIdx = 0;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedIdx = now.weekday - 1;
    _weekStart = agendaWeekStart(now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.track(ProductEvents.agendaViewed);
    });
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final keepStale = _ags.isNotEmpty;
    try {
      final monday = DateTime(
        _weekStart.year,
        _weekStart.month,
        _weekStart.day,
      );
      final currentMonday = agendaWeekStart(DateTime.now());
      final iso = agendaIsoDate(monday);
      final List<Agendamento> items;
      if (agendaSameDay(monday, currentMonday)) {
        if (force) invalidateAgendaCaches(ref);
        if (!keepStale) {
          setState(() {
            _loading = true;
            _erro = null;
          });
        }
        items = (await ref.read(agendaHomeProvider.future)).firstPaintItems;
      } else {
        final cached = force ? null : AgendaWeekClientCache.get(iso);
        if (cached != null) {
          if (!mounted) return;
          setState(() {
            _ags = cached;
            _loading = false;
            _erro = null;
            _fetchedAt = DateTime.now();
          });
          return;
        }
        setState(() {
          _loading = true;
          _erro = null;
        });
        items = await ref.read(agendaRepositoryProvider).listarSemana(iso);
        AgendaWeekClientCache.put(iso, items);
      }
      if (!mounted) return;
      setState(() {
        _ags = items;
        _loading = false;
        _erro = null;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      if (keepStale) {
        setState(() => _loading = false);
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível atualizar a agenda.'),
        );
      } else {
        setState(() {
          _loading = false;
          _erro = e;
        });
      }
    }
  }

  Future<void> _novoAgendamento({DateTime? slot}) async {
    final selectedDate = slot ?? _weekStart.add(Duration(days: _selectedIdx));
    await context.push('/agenda/novo', extra: selectedDate);
    if (!mounted) return;
    _load(force: true);
  }

  bool get _isTodayVisible {
    final now = DateTime.now();
    return agendaSameDay(
          DateTime(_weekStart.year, _weekStart.month, _weekStart.day),
          agendaWeekStart(now),
        ) &&
        _selectedIdx == now.weekday - 1;
  }

  void _goToday() {
    final now = DateTime.now();
    final monday = agendaWeekStart(now);
    final sameWeek = agendaSameDay(
      DateTime(_weekStart.year, _weekStart.month, _weekStart.day),
      monday,
    );
    setState(() {
      _weekStart = monday;
      _selectedIdx = now.weekday - 1;
    });
    if (!sameWeek) _load();
  }

  void _changeWeek(int delta) {
    final next = _weekStart.add(Duration(days: delta * 7));
    final now = DateTime.now();
    final todayMonday = agendaWeekStart(now);
    setState(() {
      _weekStart = DateTime(next.year, next.month, next.day);
      _selectedIdx =
          agendaSameDay(_weekStart, todayMonday) ? now.weekday - 1 : 0;
    });
    _load();
  }

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
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final diasSemanaStr = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    final eventosMap = agendaEventsByWeekday(_ags, _weekStart);
    final dailyEvents = [...(eventosMap[_selectedIdx] ?? <Agendamento>[])]
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final visible = agendaVisibleEvents(dailyEvents);
    final nextOpen = agendaNextOpen(visible);
    final showNextBanner = nextOpen != null && _isTodayVisible;
    final lane = agendaBuildDayLane(
      dailyEvents,
      excludeNextFromLane: showNextBanner,
    );
    final cancelled = agendaCancelledCount(dailyEvents);
    final selectedDate = _weekStart.add(Duration(days: _selectedIdx));
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final now = DateTime.now();
    final dayHeading = agendaDayHeading(
      weekdayLabel: diasSemanaStr[_selectedIdx],
      date: selectedDate,
      visibleCount: visible.length,
    );
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
                  onToday: _isTodayVisible ? null : _goToday,
                  onNew: () => _novoAgendamento(),
                ),
                AgendaWeekBar(
                  weekStart: _weekStart,
                  onPrev: () => _changeWeek(-1),
                  onNext: () => _changeWeek(1),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    0,
                    TokensStrip.s4,
                    TokensStrip.s3,
                  ),
                  child: Row(
                    children: List.generate(7, (i) {
                      final dayDate = _weekStart.add(Duration(days: i));
                      final count =
                          agendaVisibleEvents(
                            eventosMap[i] ?? const <Agendamento>[],
                          ).length;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i == 6 ? 0 : TokensStrip.s1,
                          ),
                          child: AgendaDayChip(
                            weekdayLabel: diasSemanaStr[i],
                            dayNumber: dayDate.day,
                            selected: i == _selectedIdx,
                            count: count,
                            isToday: agendaSameDay(dayDate, now),
                            width: double.infinity,
                            onTap: () => setState(() => _selectedIdx = i),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (nextOpen != null && _isTodayVisible)
                  AgendaNextBanner(
                    agendamento: nextOpen,
                    photoUrl: _photoFor(nextOpen.alunoId),
                    onTap: () => _openAgendamentoDetails(nextOpen),
                  )
                else if (!_loading && _erro == null && visible.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      TokensStrip.s4,
                      TokensStrip.s2,
                    ),
                    child: DashboardSectionHeader(title: dayHeading),
                  ),
                Expanded(
                  child:
                      _erro != null
                          ? FxErrorState(
                            chromeOnDark: isDark,
                            primary: primary,
                            message: friendlyError(_erro!),
                            onRetry: () => _load(force: true),
                          )
                          : _loading
                          ? const SkeletonList(count: 4)
                          : RefreshIndicator(
                            color: primary,
                            onRefresh: () {
                              AnalyticsService.instance.track(
                                ProductEvents.agendaRefreshed,
                              );
                              return _load(force: true);
                            },
                            child:
                                visible.isEmpty
                                    ? CustomScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      slivers: [
                                        SliverPadding(
                                          padding: EdgeInsets.fromLTRB(
                                            TokensStrip.s4,
                                            TokensStrip.s1,
                                            TokensStrip.s4,
                                            DashboardLayout.bottomDockClearance,
                                          ),
                                          sliver: SliverToBoxAdapter(
                                            child: AgendaDayEmptyPanel(
                                              dayLabel: dayHeading,
                                              onNew: () => _novoAgendamento(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: const EdgeInsets.fromLTRB(
                                        FxSettingsLayout.pageInset,
                                        0,
                                        FxSettingsLayout.pageInset,
                                        DashboardLayout.bottomDockClearance,
                                      ),
                                      children: [
                                        for (var i = 0; i < lane.length; i++)
                                          if (lane[i] is AgendaLaneGap)
                                            AgendaGapTile(
                                              label: agendaGapLabel(
                                                (lane[i] as AgendaLaneGap)
                                                    .duration,
                                              ),
                                              onTap:
                                                  () => _novoAgendamento(
                                                    slot:
                                                        (lane[i]
                                                                as AgendaLaneGap)
                                                            .from,
                                                  ),
                                            )
                                          else
                                            AgendaEventCard(
                                              agendamento:
                                                  (lane[i] as AgendaLaneEvent)
                                                      .agendamento,
                                              photoUrl: _photoFor(
                                                (lane[i] as AgendaLaneEvent)
                                                    .agendamento
                                                    .alunoId,
                                              ),
                                              emphasized:
                                                  (lane[i] as AgendaLaneEvent)
                                                      .next,
                                              onTap:
                                                  () => _openAgendamentoDetails(
                                                    (lane[i] as AgendaLaneEvent)
                                                        .agendamento,
                                                  ),
                                            ),
                                        if (cancelled > 0) ...[
                                          const SizedBox(
                                            height:
                                                FxSettingsLayout
                                                    .footerAfterGroup,
                                          ),
                                          Text(
                                            cancelled == 1
                                                ? '1 horário cancelado oculto'
                                                : '$cancelled horários cancelados ocultos',
                                            textAlign: TextAlign.center,
                                            style: FocuxHubTypography.bodyMuted(
                                              color: chrome.mute,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
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
