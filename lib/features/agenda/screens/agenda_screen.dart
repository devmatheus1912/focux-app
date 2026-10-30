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
import '../widgets/agenda_dia_view.dart';
import '../widgets/agenda_month_grid.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../widgets/agenda_help_sheet.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../widgets/agenda_slot_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';

part 'agenda_screen_actions.part.dart';
part 'agenda_screen_widgets.part.dart';

enum AgendaVisao { dia, mes }

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});
  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  List<Agendamento> _ags = [];
  Object? _erro;
  late DateTime _mes;
  late DateTime _dia;
  var _visao = AgendaVisao.dia;

  static const _visaoKey = 'agenda_visao';

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
    _lerVisao();
  }

  Future<void> _lerVisao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted && prefs.getString(_visaoKey) == AgendaVisao.mes.name) {
        setState(() => _visao = AgendaVisao.mes);
      }
    } catch (_) {}
  }

  void _trocarVisao(AgendaVisao visao) {
    setState(() => _visao = visao);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_visaoKey, visao.name))
        .ignore();
  }

  void _setAgs(List<Agendamento> items) => _ags = items;

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

  /// Tocar um dia no mês leva à lista dele.
  void _openDay(DateTime day) {
    _selectDay(day);
    _trocarVisao(AgendaVisao.dia);
  }

  Future<void> _menu() async {
    final s = S.of(context);
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: s.agendaMenuTitulo,
      icone: Icons.more_horiz_rounded,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'calendario',
            rotulo: s.agendaConectarCalendario,
            descricao: s.agendaConectarCalendarioTexto,
            icone: Icons.event_available_outlined,
          ),
        ]),
      ],
    );
    if (escolha == 'calendario' && mounted) await _copyIcalLink();
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
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final showError = _erro != null && _ags.isEmpty;
    final porDia = agendaVisibleByDay(_ags);
    return fxScreenA11yScope(
      label: 'Agenda',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        extendBody: true,
        appBar: FxShellAppBar(
          title: 'Agenda',
          showBack: false,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar a agenda',
              onTap: () {
                AnalyticsService.instance.track(ProductEvents.agendaHelpOpened);
                showAgendaHelpSheet(context);
              },
            ),
            IconButton(
              tooltip: 'Novo agendamento',
              onPressed: () => _novoAgendamento(),
              icon: const Icon(Icons.add_rounded),
            ),
            IconButton(
              tooltip: s.agendaMenuTitulo,
              onPressed: _menu,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: DashboardLayout.bottomDockClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    0,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: Row(
                    children: [
                      FxChoiceStrip<AgendaVisao>(
                        itens: [
                          FxChoiceItem(value: AgendaVisao.dia, label: s.agendaVisaoDia),
                          FxChoiceItem(value: AgendaVisao.mes, label: s.agendaVisaoMes),
                        ],
                        selecionado: _visao,
                        onSelecionar: _trocarVisao,
                      ),
                      const Spacer(),
                      if (!_isTodayVisible)
                        FxTonalButton(
                          label: s.agendaHoje,
                          compact: true,
                          onPressed: _goToday,
                        ),
                    ],
                  ),
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
                          : _visao == AgendaVisao.mes
                          ? AgendaMonthGrid(
                            month: _mes,
                            selected: _dia,
                            eventsByDay: porDia,
                            onSelect: _openDay,
                            onSwipe: _changeMonth,
                            expand: true,
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AgendaSemanaFaixa(
                                dia: _dia,
                                porDia: porDia,
                                onDia: _selectDay,
                              ),
                              Expanded(
                                child: AgendaDiaLista(
                                  dia: _dia,
                                  agendamentos: _ags,
                                  photoFor: _photoFor,
                                  onRefresh: () {
                                    AnalyticsService.instance.track(
                                      ProductEvents.agendaRefreshed,
                                    );
                                    return _load(force: true);
                                  },
                                  onOpen: _openAgendamentoDetails,
                                  onNew:
                                      (slot, duracaoMin) => _novoAgendamento(
                                        day: _dia,
                                        slot: slot,
                                        duracaoMin: duracaoMin,
                                      ),
                                  onPresenca: _registrarPresenca,
                                ),
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
