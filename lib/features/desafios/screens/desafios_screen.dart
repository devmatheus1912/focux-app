import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
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
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

part 'desafios_screen_form.part.dart';

final _repo = Provider((ref) => DesafioRepository(ref.read(apiClientProvider)));

class DesafiosScreen extends ConsumerStatefulWidget {
  const DesafiosScreen({super.key});

  @override
  ConsumerState<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends ConsumerState<DesafiosScreen> {
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
      final pagina = await ref.read(_repo).listarPagina(
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
      final pagina = await ref.read(_repo).listarPagina(
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

  void _abrirDetalhe(Desafio d) {
    context.push(desafioDetailPath(d.id), extra: d);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

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
              _loading ? null : freshnessLabel,
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/perfil/ferramentas');
            },
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar desafios',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Desafios',
                  subtitle: 'Campanha com prazo, meta e ranking.',
                  tips: const [
                    FxHelpTip(
                      'Criar',
                      'Título, tipo, prazo e meta. O ranking soma hábitos ou treinos.',
                    ),
                    FxHelpTip(
                      'Participar',
                      'Alunos ativos entram na criação. Encerrar tira da lista.',
                    ),
                  ],
                ),
              ),
            ],
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
                  message: _error!,
                  onRetry: _load,
                )
              : Column(
                  children: [
                    Expanded(
                      child: FxContentWidthLimiter(child: _buildBody()),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s2,
                          TokensStrip.s4,
                          TokensStrip.s3 +
                              MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        child: FxLiquidPrimaryButton(
                          label: 'Novo desafio',
                          onPressed: _criar,
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

  Widget _buildBody() {
    final searching = _query.isNotEmpty || _filtro != DesafioTipoFiltro.todos;
    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              TokensStrip.s2,
              TokensStrip.s4,
              TokensStrip.s2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                  decoration: InputDecoration(
                    hintText: 'Buscar desafio',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    for (final filtro in const [
                      DesafioTipoFiltro.habitos,
                      DesafioTipoFiltro.treinos,
                    ])
                      FxToggleChip(
                        label: desafioFiltroLabel(filtro),
                        selected: _filtro == filtro,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        onTap: () {
                          final next = _filtro == filtro
                              ? DesafioTipoFiltro.todos
                              : filtro;
                          setState(() => _filtro = next);
                          _load();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32,
              ),
              itemCount: _desafios.isEmpty
                  ? 1
                  : _desafios.length + 2 + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (_desafios.isEmpty) {
                  return FxEmptyState(
                    icon: searching ? 'search' : 'spark',
                    title: searching
                        ? 'Nada neste filtro'
                        : 'Nenhum desafio',
                    subtitle: searching
                        ? 'Ajuste a busca ou o tipo para ver outros.'
                        : 'Crie o primeiro desafio com prazo e meta.',
                    action: FxEmptyAction(
                      label: searching ? 'Limpar filtros' : 'Criar desafio',
                      onTap: searching ? _clearFilters : _criar,
                    ),
                  );
                }
                if (index == 0) {
                  return const DashboardSectionHeader(title: 'Desafios ativos');
                }
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: TokensStrip.s2,
                      bottom: TokensStrip.s3,
                    ),
                    child: Text(
                      'Toque para abrir prazo, meta e ranking.',
                      style: FocuxHubTypography.bodyMuted(
                        color: fxScreenMute(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                if (_hasMore && index == _desafios.length + 2) {
                  return FxSatelliteListTile(
                    title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                    onTap: _loadingMore ? null : _carregarMais,
                  );
                }
                final desafio = _desafios[index - 2];
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
                  onTap: () => _abrirDetalhe(desafio),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
