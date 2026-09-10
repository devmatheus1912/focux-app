import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/grupo_aula_repository.dart';
import '../utils/grupo_aula_display.dart';

class GrupoAulasAlunoScreen extends ConsumerStatefulWidget {
  const GrupoAulasAlunoScreen({super.key});

  @override
  ConsumerState<GrupoAulasAlunoScreen> createState() =>
      _GrupoAulasAlunoScreenState();
}

class _GrupoAulasAlunoScreenState extends ConsumerState<GrupoAulasAlunoScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<GrupoAula> _aulas = [];
  var _query = '';
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
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _load();
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await GrupoAulaRepository(
        ref.read(apiClientProvider),
      ).disponiveisPagina(q: _query);
      if (!mounted) return;
      setState(() {
        _aulas = pagina.content;
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
      final pagina = await GrupoAulaRepository(
        ref.read(apiClientProvider),
      ).disponiveisPagina(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _aulas.map((a) => a.id).toSet();
      setState(() {
        _aulas = [
          ..._aulas,
          ...pagina.content.where((a) => seen.add(a.id)),
        ];
        _page = pagina.page ?? (_page + 1);
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _aulas.length;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _inscrever(GrupoAula aula) async {
    if (aula.lotada) {
      await showFxNoticeSheet(
        context,
        title: 'Aula lotada',
        message: 'Essa turma já encheu. Fique de olho na próxima abertura.',
      );
      return;
    }
    final ok = await showFxConfirmSheet(
      context,
      title: 'Inscrever nesta aula?',
      message: aula.titulo,
      confirmLabel: 'Inscrever',
      icon: Icons.groups_outlined,
    );
    if (!ok || !mounted) return;
    try {
      await GrupoAulaRepository(ref.read(apiClientProvider)).inscrever(aula.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Inscrição confirmada!');
      await _load();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searching = _query.isNotEmpty;

    return fxScreenA11yScope(
      label: 'Aulas em grupo',
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
            title: 'Aulas em grupo',
            subtitle: FxHubFreshness.joinCount(
              grupoAulaCountLabel(_loading ? 0 : _total),
              _loading ? null : freshnessLabel,
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/dashboard/aluno');
            },
          ),
          body: _loading
              ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 4),
                )
              : _erro != null
              ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: scheme.primary,
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
                        onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                        decoration: InputDecoration(
                          hintText: 'Buscar aula',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FxContentWidthLimiter(child: _buildList(searching)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildList(bool searching) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _aulas.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const SizedBox(height: 48),
                FxEmptyState(
                  icon: searching ? 'search' : 'calendar',
                  title: searching
                      ? 'Nenhuma aula encontrada'
                      : 'Nenhuma aula disponível',
                  subtitle: searching
                      ? 'Tente outro nome ou local.'
                      : 'Quando seu personal abrir uma aula em grupo, ela aparece aqui. Dúvida? Fale no chat.',
                  action: searching
                      ? FxEmptyAction(label: 'Limpar busca', onTap: _clearQuery)
                      : FxEmptyAction(
                          label: 'Abrir chat',
                          onTap: () => context.push('/chat/aluno'),
                        ),
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
              itemCount: _aulas.length + (_hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _aulas.length) {
                  return FxSatelliteListTile(
                    title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                    onTap: _loadingMore ? null : _carregarMais,
                  );
                }
                final a = _aulas[i];
                final lotada = grupoAulaLotada(
                  inscritos: a.inscritos,
                  capacidadeMax: a.capacidadeMax,
                );
                return FxSatelliteListTile(
                  title: a.titulo,
                  titleCase: false,
                  subtitle: Text(
                    '${grupoAulaSubtitle(inicio: a.inicio, localAula: a.localAula)} · ${grupoAulaVagasLabel(inscritos: a.inscritos, capacidadeMax: a.capacidadeMax)}',
                  ),
                  trailing: Text(
                    lotada ? 'Lotada' : 'Inscrever',
                    style: FocuxHubTypography.bodyMuted(
                      color: lotada
                          ? EagleTokens.warn
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => _inscrever(a),
                );
              },
            ),
    );
  }
}
