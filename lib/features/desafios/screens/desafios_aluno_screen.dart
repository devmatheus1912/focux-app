import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

final _repo = Provider((ref) => DesafioRepository(ref.read(apiClientProvider)));

class DesafiosAlunoScreen extends ConsumerStatefulWidget {
  const DesafiosAlunoScreen({super.key});

  @override
  ConsumerState<DesafiosAlunoScreen> createState() =>
      _DesafiosAlunoScreenState();
}

class _DesafiosAlunoScreenState extends ConsumerState<DesafiosAlunoScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<Desafio> _desafios = [];
  var _filtro = DesafioTipoFiltro.todos;
  var _query = '';
  var _page = 0;
  var _hasMore = false;
  var _total = 0;
  var _loadingMore = false;
  var _loading = true;
  String? _error;
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
      _filtro = DesafioTipoFiltro.todos;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pagina = await ref.read(_repo).meusPagina(
        q: _query,
        tipo: desafioFiltroTipo(_filtro),
      );
      if (!mounted) return;
      setState(() {
        _desafios = pagina.content;
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
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await ref.read(_repo).meusPagina(
        page: _page + 1,
        q: _query,
        tipo: desafioFiltroTipo(_filtro),
      );
      if (!mounted) return;
      final seen = _desafios.map((d) => d.id).toSet();
      setState(() {
        _desafios = [
          ..._desafios,
          ...pagina.content.where((d) => seen.add(d.id)),
        ];
        _page = pagina.page ?? (_page + 1);
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _desafios.length;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  void _abrir(Desafio d) {
    context.push(desafioAlunoDetailPath(d.id), extra: d);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searching = _query.isNotEmpty || _filtro != DesafioTipoFiltro.todos;

    return fxScreenA11yScope(
      label: 'Desafios',
      child: FeatureGate(
        featureName: 'Desafios',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'comunidadeGrupos',
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
              title: 'Desafios',
              subtitle: FxHubFreshness.joinCount(
                desafioCountLabel(_loading ? 0 : _total),
                _loading ? null : freshness,
              ),
              onBack: () {
                FxKeyboardDismissScope.dismiss();
                safePopOrGo(context, '/dashboard/aluno');
              },
            ),
            body: _loading
                ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 5),
                  )
                : _error != null
                ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: scheme.primary,
                    title: FocuxMicrocopy.naoFoiPossivelCarregar,
                    message: _error!,
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
                            hintText: 'Buscar desafio',
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
                            for (final filtro in DesafioTipoFiltro.values) ...[
                              if (filtro != DesafioTipoFiltro.values.first)
                                const SizedBox(width: TokensStrip.s2),
                              FxToggleChip(
                                label: desafioFiltroLabel(filtro),
                                selected: _filtro == filtro,
                                isDark: chrome.isDark,
                                onTap: () {
                                  if (_filtro == filtro) return;
                                  setState(() => _filtro = filtro);
                                  _load();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: FxContentWidthLimiter(
                          child: _buildList(searching),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(bool searching) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _desafios.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const SizedBox(height: 48),
                FxEmptyState(
                  icon: searching ? 'search' : 'spark',
                  title: searching
                      ? 'Nenhum desafio encontrado'
                      : 'Nenhum desafio agora',
                  subtitle: searching
                      ? 'Ajuste a busca ou o filtro para achar outra campanha.'
                      : 'Quando seu personal abrir uma campanha, ela aparece aqui.',
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
              itemCount: _desafios.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _desafios.length) {
                  return FxSatelliteListTile(
                    title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                    onTap: _loadingMore ? null : _carregarMais,
                  );
                }
                final desafio = _desafios[index];
                return FxSatelliteListTile(
                  title: desafio.titulo,
                  subtitle: Text(
                    desafioSubtitle(
                      tipo: desafio.tipo,
                      metaPontos: desafio.metaPontos,
                      inicio: desafio.inicio,
                      fim: desafio.fim,
                    ),
                  ),
                  trailing: Text(
                    desafioMetaLabel(desafio.metaPontos),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => _abrir(desafio),
                );
              },
            ),
    );
  }
}
