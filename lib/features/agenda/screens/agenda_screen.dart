import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
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
import '../widgets/agenda_day_chip.dart';
import '../widgets/agenda_event_card.dart';
import '../widgets/agenda_help_sheet.dart';
import '../widgets/agenda_hub_header.dart';
import '../widgets/agenda_next_banner.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/constants/dashboard_layout.dart';
import '../../dashboard/utils/dashboard_readability.dart';

part 'agenda_screen_widgets.part.dart';
part 'agenda_screen_novo.part.dart';

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
    final selectedDate =
        slot ?? _weekStart.add(Duration(days: _selectedIdx));
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
    final list = ref.read(alunosProvider).valueOrNull;
    if (list == null) return null;
    for (final aluno in list) {
      if (aluno.id == alunoId) return aluno.fotoUrl;
    }
    return null;
  }

  Aluno? _alunoFromCache(int alunoId) {
    final list = ref.read(alunosProvider).valueOrNull;
    if (list == null) return null;
    for (final aluno in list) {
      if (aluno.id == alunoId) return aluno;
    }
    return null;
  }

  Future<bool> _confirmDestructive({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final chrome = ShellChrome.of(ctx);
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Voltar', style: TextStyle(color: chrome.mute)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  Future<void> _setStatus(Agendamento ag, String status) async {
    await ref.read(agendaRepositoryProvider).atualizarStatus(ag.id, status);
    if (!mounted) return;
    Navigator.pop(context);
    await _load(force: true);
    if (!mounted) return;
    AnalyticsService.instance.track(
      ProductEvents.agendaStatusChanged,
      props: {'status': status},
    );
    FeedbackHelper.showSuccess(
      context,
      status == 'CONFIRMADO'
          ? 'Horário confirmado.'
          : status == 'CONCLUIDO'
          ? 'Atendimento concluído.'
          : 'Horário cancelado.',
    );
  }

  Future<void> _reschedule(Agendamento ag) async {
    final dt = await showFxHomeSheet<DateTime>(
      context,
      builder:
          (_) => _AgendaDateTimeSheet(
            title: 'Novo início',
            initial: ag.inicio,
          ),
    );
    if (dt == null || !mounted) return;
    final fim = dt.add(ag.fim.difference(ag.inicio));
    await ref
        .read(agendaRepositoryProvider)
        .atualizarHorario(ag.id, dt, fim, titulo: ag.titulo);
    if (!mounted) return;
    Navigator.pop(context);
    await _load(force: true);
    if (!mounted) return;
    AnalyticsService.instance.track(ProductEvents.agendaRescheduled);
    FeedbackHelper.showSuccess(context, 'Horário remarcado.');
  }

  /// Combina `Env.apiUrl` (https://host[/api]) com um path relativo (/api/...) sem
  /// duplicar segmentos. Aceita também URL já absoluta vinda do backend.
  String _resolveAbsoluteApiUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    var base = Env.apiUrl;
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    if (base.endsWith('/api') && path.startsWith('/api/')) {
      base = base.substring(0, base.length - 4);
    }
    return '$base$path';
  }

  Future<void> _copyIcalLink() async {
    try {
      final info = await ref.read(agendaRepositoryProvider).icalToken();
      final fullUrl = _resolveAbsoluteApiUrl(info.url);
      await Clipboard.setData(ClipboardData(text: fullUrl));
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Link iCal copiado — cole no Google Calendar ou Apple Calendar.',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Erro ao gerar link iCal.'),
        );
      }
    }
  }

  Future<void> _openAgendamentoDetails(Agendamento ag) async {
    Aluno? aluno = _alunoFromCache(ag.alunoId);
    try {
      aluno = await ref.read(alunoProvider(ag.alunoId).future);
    } catch (_) {}
    if (!mounted) return;
    final digits = (aluno?.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final actionable = agendaStatusIsActionable(ag.status);

    await showFxHomeSheet<void>(
      context,
      builder:
          (_) => _AgendaEventSheet(
            agendamento: ag,
            statusLabel: agendaStatusLabel(ag.status),
            photoUrl: aluno?.fotoUrl ?? _photoFor(ag.alunoId),
            onOpenAluno: () async {
              Navigator.pop(context);
              if (!mounted) return;
              AnalyticsService.instance.track(ProductEvents.agendaAlunoOpened);
              context.push('/alunos/${ag.alunoId}');
            },
            onWhatsapp:
                digits.isEmpty
                    ? null
                    : () {
                      AnalyticsService.instance.track(
                        ProductEvents.agendaWhatsapp,
                      );
                      return openAlunoWhatsappOutreach(
                        context,
                        displayName: ag.alunoNome,
                        whatsappNumber: digits,
                        emRisco: aluno?.emRisco ?? false,
                        message: agendaWhatsappReminder(
                          alunoNome: ag.alunoNome,
                          inicio: ag.inicio,
                        ),
                      );
                    },
            onConfirm:
                agendaStatusNeedsConfirm(ag.status)
                    ? () => _setStatus(ag, 'CONFIRMADO')
                    : null,
            onComplete:
                actionable ? () => _setStatus(ag, 'CONCLUIDO') : null,
            onCancel:
                actionable
                    ? () async {
                      final ok = await _confirmDestructive(
                        title: 'Cancelar horário?',
                        body:
                            'O horário com ${ag.alunoNome} deixa de aparecer como ativo.',
                        confirmLabel: 'Cancelar horário',
                      );
                      if (!ok) return;
                      await _setStatus(ag, 'CANCELADO');
                    }
                    : null,
            onReschedule:
                actionable ? () => _reschedule(ag) : null,
            onDelete: () async {
              final ok = await _confirmDestructive(
                title: 'Excluir atendimento?',
                body: 'Isso remove o horário com ${ag.alunoNome} da agenda.',
                confirmLabel: 'Excluir',
              );
              if (!ok) return;
              await ref.read(agendaRepositoryProvider).excluir(ag.id);
              if (!mounted) return;
              Navigator.pop(context);
              await _load(force: true);
              if (!mounted) return;
              AnalyticsService.instance.track(ProductEvents.agendaDeleted);
              FeedbackHelper.showSuccess(context, 'Agendamento excluído.');
            },
          ),
    );
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
    final lane = agendaBuildDayLane(dailyEvents);
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
                    AnalyticsService.instance.track(ProductEvents.agendaHelpOpened);
                    showAgendaHelpSheet(context);
                  },
                  onIcal: _copyIcalLink,
                  onToday: _isTodayVisible ? null : _goToday,
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
                      final count = agendaVisibleEvents(
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
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      TokensStrip.s4,
                      TokensStrip.s2,
                    ),
                    child: Text(
                      dayHeading,
                      style: dashboardPageTitleStyle(
                        context,
                        color: chrome.ink,
                      ).copyWith(fontSize: 16),
                    ),
                  ),
                Expanded(
                  child: _erro != null
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
                          child: visible.isEmpty
                              ? CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(
                                        TokensStrip.s4,
                                        TokensStrip.s1,
                                        TokensStrip.s4,
                                        TokensStrip.s3,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: DecoratedBox(
                                          decoration: fxStripCardDecoration(
                                            context,
                                            accent: primary,
                                            radius: TokensStrip.rCard,
                                            glowStrength: 0.04,
                                          ),
                                          child: FxEmptyState(
                                            icon: 'calendar',
                                            title: 'Dia livre',
                                            subtitle: agendaEmptyDaySubtitle(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    TokensStrip.s4,
                                    0,
                                    TokensStrip.s4,
                                    TokensStrip.s3,
                                  ),
                                  itemCount: lane.length + (cancelled > 0 ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: TokensStrip.s2),
                                  itemBuilder: (_, i) {
                                    if (i >= lane.length) {
                                      return Text(
                                        cancelled == 1
                                            ? '1 horário cancelado oculto'
                                            : '$cancelled horários cancelados ocultos',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: chrome.mute,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }
                                    final item = lane[i];
                                    if (item is AgendaLaneGap) {
                                      return AgendaGapTile(
                                        label: agendaGapLabel(item.duration),
                                        onTap: () =>
                                            _novoAgendamento(slot: item.from),
                                      );
                                    }
                                    final ev = item as AgendaLaneEvent;
                                    return AgendaEventCard(
                                      agendamento: ev.agendamento,
                                      photoUrl: _photoFor(ev.agendamento.alunoId),
                                      emphasized: ev.next,
                                      onTap: () => _openAgendamentoDetails(
                                        ev.agendamento,
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
                if (!_loading && _erro == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      TokensStrip.s1,
                      TokensStrip.s4,
                      DashboardLayout.bottomDockClearance,
                    ),
                    child: Semantics(
                      button: true,
                      label: 'Novo agendamento',
                      child: FxLiquidPrimaryButton(
                        label: 'Novo agendamento',
                        onPressed: () => _novoAgendamento(),
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
