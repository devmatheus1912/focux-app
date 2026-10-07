import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/pagina.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/data/aluno_onboarding_prefs.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_display.dart';
import '../utils/agenda_status.dart';

class AgendaAlunoScreen extends ConsumerStatefulWidget {
  const AgendaAlunoScreen({super.key});
  @override
  ConsumerState<AgendaAlunoScreen> createState() => _AgendaAlunoScreenState();
}

/// Uma lista paginada por escopo (próximas / anteriores).
class _Secao {
  _Secao(this.escopo);

  final String escopo;
  List<Agendamento> items = [];
  var page = 0;
  var hasMore = false;
  var total = 0;
  var loadingMore = false;

  void reset(Pagina<Agendamento> pagina) {
    items = pagina.content;
    page = pagina.page ?? 0;
    hasMore = pagina.hasNext;
    total = pagina.totalElements ?? pagina.content.length;
  }

  void append(Pagina<Agendamento> pagina) {
    final seen = items.map((a) => a.id).toSet();
    items = [...items, ...pagina.content.where((a) => seen.add(a.id))];
    page = pagina.page ?? (page + 1);
    hasMore = pagina.hasNext;
    total = pagina.totalElements ?? items.length;
  }
}

class _AgendaAlunoScreenState extends ConsumerState<AgendaAlunoScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _proximas = _Secao(agendaAlunoEscopoProximas);
  final _anteriores = _Secao(agendaAlunoEscopoAnteriores);
  Timer? _debounce;
  var _query = '';
  var _chip = AgendaAlunoChip.todos;
  var _anterioresAbertas = false;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    unawaited(
      markAlunoAgendaReviewed(
        ref.read(alunoDashboardHomeProvider).value?.agendaProximoInicio,
      ),
    );
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _load();
    });
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _chip = AgendaAlunoChip.todos;
    });
    _load();
  }

  Future<Pagina<Agendamento>> _fetch(_Secao secao, {int page = 0}) =>
      AgendaRepository(ref.read(apiClientProvider)).meusAgendamentosPagina(
        page: page,
        q: _query,
        status: agendaAlunoChipStatus(_chip),
        escopo: secao.escopo,
      );

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final paginas = await Future.wait([
        _fetch(_proximas),
        _fetch(_anteriores),
      ]);
      if (!mounted) return;
      setState(() {
        _proximas.reset(paginas[0]);
        _anteriores.reset(paginas[1]);
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais(_Secao secao) async {
    if (secao.loadingMore || !secao.hasMore) return;
    setState(() => secao.loadingMore = true);
    try {
      final pagina = await _fetch(secao, page: secao.page + 1);
      if (!mounted) return;
      setState(() {
        secao.append(pagina);
        secao.loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => secao.loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

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
      final info =
          await AgendaRepository(ref.read(apiClientProvider)).icalTokenAluno();
      final fullUrl = _resolveAbsoluteApiUrl(info.url);
      await Clipboard.setData(ClipboardData(text: fullUrl));
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        'Link iCal copiado — cole no Google Calendar ou Apple Calendar.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _confirmar(Agendamento ag) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Confirmar presença?',
      subtitle: agendaAlunoDefaultTitle(ag.titulo),
      message: agendaAlunoDiaLabel(ag.inicio, ag.fim),
      confirmLabel: 'Confirmar',
      confirmIcon: Icons.check_rounded,
      icon: Icons.event_available_rounded,
    );
    if (!ok || !mounted) return;
    try {
      final atualizado = await AgendaRepository(
        ref.read(apiClientProvider),
      ).confirmarPresenca(ag.id);
      if (!mounted) return;
      setState(() {
        _proximas.items = [
          for (final item in _proximas.items)
            item.id == atualizado.id ? atualizado : item,
        ];
      });
      FeedbackHelper.showSuccess(context, 'Presença confirmada!');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showApiFailure(context, e);
    }
  }

  Future<void> _onAgTap(Agendamento ag) async {
    if (agendaAlunoPodeConfirmar(ag)) {
      await _confirmar(ag);
      return;
    }
    await showFxNoticeSheet(
      context,
      title: agendaAlunoDefaultTitle(ag.titulo),
      message:
          '${agendaAlunoDiaLabel(ag.inicio, ag.fim)}\n${agendaAlunoStatusLabel(ag)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searching = _query.isNotEmpty || _chip != AgendaAlunoChip.todos;

    return fxScreenA11yScope(
      label: 'Minha Agenda',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          safePopOrGo(context, '/dashboard/aluno');
        },
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Minha Agenda',
            subtitle: FxHubFreshness.joinCount(
              _loading
                  ? s.agendaAlunoCarregando
                  : agendaAlunoCountLabel(_proximas.total + _anteriores.total),
              _loading ? null : freshness,
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/dashboard/aluno');
            },
            actions: [
              IconButton(
                tooltip: s.agendaAlunoAdicionarCalendario,
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: _copyIcalLink,
              ),
            ],
          ),
          body: FxContentWidthLimiter(
            child:
                _loading
                    ? const Padding(
                      padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                      child: SkeletonList(count: 4),
                    )
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      message: _erro!,
                      onRetry: _load,
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2,
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            textInputAction: TextInputAction.search,
                            onChanged: _onQueryChanged,
                            onTapOutside:
                                (_) => FxKeyboardDismissScope.dismiss(),
                            decoration: InputDecoration(
                              hintText: 'Buscar sessão',
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            0,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2,
                          ),
                          child: Wrap(
                            spacing: TokensStrip.s2,
                            runSpacing: TokensStrip.s2,
                            children: [
                              for (final chip in AgendaAlunoChip.values)
                                FxToggleChip(
                                  label: agendaAlunoChipLabel(chip),
                                  selected: _chip == chip,
                                  isDark: chrome.isDark,
                                  onTap: () {
                                    if (_chip == chip) return;
                                    setState(() => _chip = chip);
                                    _load();
                                  },
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildList(s, searching, chrome, primary),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(S s, bool searching, ShellPalette chrome, Color primary) {
    final proximas = agendaAlunoProximas(_proximas.items);
    final anteriores = agendaAlunoAnteriores(_anteriores.items);
    if (proximas.isEmpty && anteriores.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const SizedBox(height: 48),
            FxEmptyState(
              icon: searching ? 'search' : 'calendar',
              title:
                  searching
                      ? 'Nenhum compromisso encontrado'
                      : 'Nenhuma sessão marcada',
              subtitle:
                  searching
                      ? 'Ajuste a busca ou o filtro para achar outra sessão.'
                      : 'Seu personal ainda não agendou nada com você. Quando marcar, aparece aqui.',
              action:
                  searching
                      ? FxEmptyAction(
                        label: 'Limpar filtros',
                        secondary: true,
                        onTap: _clearFilters,
                      )
                      : FxEmptyAction(
                        label: 'Abrir chat',
                        onTap: () => openAlunoRoute(context, '/chat/aluno'),
                      ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[
      DashboardSectionHeader(title: s.agendaAlunoProximas),
      if (proximas.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
          child: Text(
            s.agendaAlunoSemProximas,
            style: FocuxHubTypography.bodyMuted(
              color: chrome.mute,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      for (var i = 0; i < proximas.length; i++)
        _tile(s, proximas[i], chrome, primary, next: i == 0),
      if (_proximas.hasMore) _loadMoreTile(s, _proximas),
      if (anteriores.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s3),
        DashboardSectionHeader(
          title: s.agendaAlunoAnteriores,
          actionLabel:
              _anterioresAbertas
                  ? s.agendaAlunoOcultarAnteriores
                  : s.agendaAlunoVerAnteriores,
          onAction:
              () => setState(() => _anterioresAbertas = !_anterioresAbertas),
        ),
        if (_anterioresAbertas) ...[
          for (final ag in anteriores) _tile(s, ag, chrome, primary),
          if (_anteriores.hasMore) _loadMoreTile(s, _anteriores),
        ],
      ],
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s5,
        ),
        itemCount: rows.length,
        itemBuilder: (_, i) => rows[i],
      ),
    );
  }

  Widget _loadMoreTile(S s, _Secao secao) => FxSatelliteListTile(
    title:
        secao.loadingMore ? s.agendaAlunoCarregando : s.agendaAlunoCarregarMais,
    onTap: secao.loadingMore ? null : () => _carregarMais(secao),
  );

  Widget _tile(
    S s,
    Agendamento ag,
    ShellPalette chrome,
    Color primary, {
    bool next = false,
  }) {
    final passou = agendaAlunoJaPassou(ag);
    final atendimento = ag.statusAtendimento?.trim().toUpperCase();
    final cor =
        passou && atendimento == null && agendaStatusIsActionable(ag.status)
            ? chrome.mute
            : agendaStatusColor(
              passou ? (atendimento ?? ag.status) : ag.status,
              isDark: chrome.isDark,
              primary: primary,
            );
    return FxSatelliteListTile(
      title: agendaAlunoDefaultTitle(ag.titulo),
      titleCase: false,
      muted: passou,
      accent: next ? primary : null,
      subtitle: Text(agendaAlunoDiaLabel(ag.inicio, ag.fim)),
      trailing:
          agendaAlunoPodeConfirmar(ag)
              ? FxActionChip(
                label: s.agendaAlunoConfirmar,
                accent: primary,
                isDark: chrome.isDark,
                solid: next,
                onPressed: () => _confirmar(ag),
              )
              : Text(
                agendaAlunoStatusLabel(ag),
                style: FocuxHubTypography.bodyMuted(
                  color: cor,
                  fontWeight: FontWeight.w700,
                ),
              ),
      onTap: () => _onAgTap(ag),
    );
  }
}
