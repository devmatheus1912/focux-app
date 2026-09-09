import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_display.dart';
import '../utils/agenda_status.dart';

part 'agenda_aluno_screen_cards.part.dart';

class AgendaAlunoScreen extends ConsumerStatefulWidget {
  const AgendaAlunoScreen({super.key});
  @override
  ConsumerState<AgendaAlunoScreen> createState() => _AgendaAlunoScreenState();
}

class _AgendaAlunoScreenState extends ConsumerState<AgendaAlunoScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<Agendamento> _ags = [];
  var _query = '';
  var _chip = AgendaAlunoChip.todos;
  var _page = 0;
  var _hasMore = false;
  var _total = 0;
  var _loadingMore = false;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await AgendaRepository(
        ref.read(apiClientProvider),
      ).meusAgendamentosPagina(
        q: _query,
        status: agendaAlunoChipStatus(_chip),
      );
      if (!mounted) return;
      setState(() {
        _ags = pagina.content;
        _page = pagina.page ?? 0;
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? pagina.content.length;
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

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await AgendaRepository(
        ref.read(apiClientProvider),
      ).meusAgendamentosPagina(
        page: _page + 1,
        q: _query,
        status: agendaAlunoChipStatus(_chip),
      );
      if (!mounted) return;
      final seen = _ags.map((a) => a.id).toSet();
      setState(() {
        _ags = [..._ags, ...pagina.content.where((a) => seen.add(a.id))];
        _page = pagina.page ?? (_page + 1);
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _ags.length;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
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
    try {
      await AgendaRepository(
        ref.read(apiClientProvider),
      ).confirmarPresenca(ag.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Presença confirmada!');
      await _load();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searching =
        _query.isNotEmpty || _chip != AgendaAlunoChip.todos;

    return fxScreenA11yScope(
      label: 'Minha Agenda',
      child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          FxKeyboardDismissScope.dismiss();
        },
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Minha Agenda',
            subtitle: FxHubFreshness.joinCount(
              agendaAlunoCountLabel(_loading ? 0 : _total),
              _loading ? null : freshness,
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/dashboard/aluno');
            },
            actions: [
              IconButton(
                tooltip: 'Exportar iCal',
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: _copyIcalLink,
              ),
            ],
          ),
          body: _loading
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s2,
                        TokensStrip.s4,
                        TokensStrip.s2,
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onChanged: _onQueryChanged,
                        onTapOutside: (_) =>
                            FxKeyboardDismissScope.dismiss(),
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
                        TokensStrip.s4,
                        0,
                        TokensStrip.s4,
                        TokensStrip.s2,
                      ),
                      child: Row(
                        children: [
                          for (final chip in AgendaAlunoChip.values) ...[
                            if (chip != AgendaAlunoChip.values.first)
                              const SizedBox(width: TokensStrip.s2),
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
                        ],
                      ),
                    ),
                    Expanded(
                      child: FxContentWidthLimiter(
                        child: _buildList(searching, chrome.isDark, primary),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildList(bool searching, bool isDark, Color primary) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _ags.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const SizedBox(height: 48),
                FxEmptyState(
                  icon: searching ? 'search' : 'calendar',
                  title: searching
                      ? 'Nenhum compromisso encontrado'
                      : 'Nenhum agendamento',
                  subtitle: searching
                      ? 'Ajuste a busca ou o filtro para achar outra sessão.'
                      : 'Quando seu personal marcar uma sessão, ela aparece aqui.',
                  action: searching
                      ? FxEmptyAction(
                          label: 'Limpar filtros',
                          onTap: _clearFilters,
                        )
                      : null,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32,
              ),
              itemCount: _ags.length + (_hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _ags.length) {
                  return FxSatelliteListTile(
                    title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                    onTap: _loadingMore ? null : _carregarMais,
                  );
                }
                return _AgCard(
                  ag: _ags[i],
                  isDark: isDark,
                  primary: primary,
                  onConfirmar: _confirmar,
                );
              },
            ),
    );
  }
}
