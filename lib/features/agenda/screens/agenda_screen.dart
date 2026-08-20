import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
import '../utils/agenda_schedule.dart';
import '../utils/agenda_status.dart';
import '../widgets/agenda_day_chip.dart';
import '../widgets/agenda_event_card.dart';
import '../widgets/agenda_help_sheet.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
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
  int _hojeIdx = 0;
  int _selectedIdx = 0;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _hojeIdx = now.weekday - 1; // 0 = Monday, 6 = Sunday
    _selectedIdx = _hojeIdx;
    _weekStart = agendaWeekStart(now);
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final monday = DateTime(
        _weekStart.year,
        _weekStart.month,
        _weekStart.day,
      );
      final currentMonday = agendaWeekStart(DateTime.now());
      final List<Agendamento> items;
      if (agendaSameDay(monday, currentMonday)) {
        if (force) invalidateAgendaCaches(ref);
        items = (await ref.read(agendaHomeProvider.future)).firstPaintItems;
      } else {
        items = await ref
            .read(agendaRepositoryProvider)
            .listarSemana(agendaIsoDate(monday));
      }
      if (!mounted) return;
      setState(() {
        _ags = items;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = e;
        });
      }
    }
  }

  Future<void> _novoAgendamento() async {
    final selectedDate = _weekStart.add(Duration(days: _selectedIdx));
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
    FeedbackHelper.showSuccess(
      context,
      status == 'CONFIRMADO'
          ? 'Horário confirmado.'
          : status == 'CONCLUIDO'
          ? 'Atendimento concluído.'
          : 'Horário cancelado.',
    );
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
              context.push('/alunos/${ag.alunoId}');
            },
            onWhatsapp:
                digits.isEmpty
                    ? null
                    : () => openAlunoWhatsappOutreach(
                      context,
                      displayName: ag.alunoNome,
                      whatsappNumber: digits,
                      emRisco: aluno?.emRisco ?? false,
                      message: agendaWhatsappReminder(
                        alunoNome: ag.alunoNome,
                        inicio: ag.inicio,
                      ),
                    ),
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
              FeedbackHelper.showSuccess(context, 'Agendamento excluído.');
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;

    final diasSemanaStr = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    // Map events to their weekday index (0-6)
    final eventosMap = <int, List<Agendamento>>{};
    for (var i = 0; i < 7; i++) {
      eventosMap[i] = [];
    }

    for (final ag in _ags) {
      // we only consider events in the current week view to match the UI
      final diff = ag.inicio.difference(_weekStart).inDays;
      if (diff >= 0 && diff < 7) {
        eventosMap[ag.inicio.weekday - 1]?.add(ag);
      }
    }

    final dailyEvents = [...(eventosMap[_selectedIdx] ?? <Agendamento>[])]
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final nextOpen = agendaNextOpen(dailyEvents);
    final selectedDate = _weekStart.add(Duration(days: _selectedIdx));
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    final monthNames = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];

    ref.watch(alunosProvider);
    return fxScreenA11yScope(
      label: 'Agenda',
      child: FxShellScaffold(
        useMesh: true,
        extendBody: true,
        safeArea: false,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 16, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          InkWell(
                            onTap:
                                () =>
                                    safePopOrGo(context, '/dashboard/personal'),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 24,
                                color: ink,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Agenda',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dashboardPageTitleStyle(
                                context,
                                color: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FxHelpIconButton(
                          tooltip: 'Como usar a agenda',
                          onTap: () => showAgendaHelpSheet(context),
                          expandHitTarget: true,
                        ),
                        IconButton(
                          tooltip: 'Exportar iCal',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: FxHomeSheetChrome.touchTarget,
                            minHeight: FxHomeSheetChrome.touchTarget,
                          ),
                          icon: Icon(
                            Icons.calendar_month_outlined,
                            color: mute,
                            size: 22,
                          ),
                          onPressed: _copyIcalLink,
                        ),
                        if (!_isTodayVisible)
                          IconButton(
                            tooltip: 'Ir para hoje',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: FxHomeSheetChrome.touchTarget,
                              minHeight: FxHomeSheetChrome.touchTarget,
                            ),
                            icon: Icon(
                              Icons.today_outlined,
                              color: primary,
                              size: 22,
                            ),
                            onPressed: _goToday,
                          ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: chrome.headerAction(radius: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _changeWeek(-1),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.chevron_left,
                                        size: 16,
                                        color: mute,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_weekStart.day}–${_weekStart.add(const Duration(days: 6)).day} ${monthNames[_weekStart.month]}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ink,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _changeWeek(1),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: mute,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Day tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(7, (i) {
                    final dayDate = _weekStart.add(Duration(days: i));
                    final count = (eventosMap[i] ?? []).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AgendaDayChip(
                        weekdayLabel: diasSemanaStr[i],
                        dayNumber: dayDate.day,
                        selected: i == _selectedIdx,
                        count: count,
                        onTap: () => setState(() => _selectedIdx = i),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: TokensStrip.s4),

              // Today's info
              Padding(
                padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${diasSemanaStr[_selectedIdx]} · ${selectedDate.day} ${monthNames[selectedDate.month]} · ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          TextSpan(
                            text:
                                dailyEvents.length == 1
                                    ? '1 atendimento'
                                    : '${dailyEvents.length} atendimentos',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: primary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (freshnessLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        freshnessLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: mute,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Events List
              Expanded(
                child:
                    _erro != null
                        ? FxErrorState(
                          chromeOnDark: isDark,
                          primary: primary,
                          message: friendlyError(_erro!),
                          onRetry: _load,
                        )
                        : _loading
                        ? const SkeletonList(count: 4)
                        : RefreshIndicator(
                          color: primary,
                          onRefresh: () => _load(force: true),
                          child:
                              dailyEvents.isEmpty
                                  ? LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          SizedBox(
                                            height: constraints.maxHeight,
                                            child: FxEmptyState(
                                              icon: 'calendar',
                                              title: 'Dia livre',
                                              subtitle:
                                                  '${diasSemanaStr[_selectedIdx]}, ${selectedDate.day} ${monthNames[selectedDate.month]} · nenhum atendimento. O botão abaixo encaixa avaliação, retorno ou sessão.',
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  )
                                  : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      TokensStrip.s4,
                                      0,
                                      16,
                                      16,
                                    ),
                                    itemCount: dailyEvents.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final e = dailyEvents[i];
                                      return AgendaEventCard(
                                        agendamento: e,
                                        photoUrl: _photoFor(e.alunoId),
                                        emphasized: nextOpen?.id == e.id,
                                        onTap:
                                            () => _openAgendamentoDetails(e),
                                      );
                                    },
                                  ),
                        ),
              ),
              if (!_loading && _erro == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
                  child: Semantics(
                    button: true,
                    label: 'Novo agendamento',
                    child: FxLiquidPrimaryButton(
                      label: 'Novo agendamento',
                      onPressed: _novoAgendamento,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
