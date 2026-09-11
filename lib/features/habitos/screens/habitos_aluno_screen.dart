import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
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
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';

final _repoProvider = Provider(
  (ref) => HabitoRepository(ref.read(apiClientProvider)),
);

class HabitosAlunoScreen extends ConsumerStatefulWidget {
  const HabitosAlunoScreen({super.key});

  @override
  ConsumerState<HabitosAlunoScreen> createState() => _HabitosAlunoScreenState();
}

class _HabitosAlunoScreenState extends ConsumerState<HabitosAlunoScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  var _query = '';
  List<Habito> _habitos = [];
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
    _carregar();
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
      _carregar();
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pagina = await ref.read(_repoProvider).meusHabitosPagina(q: _query);
      if (!mounted) return;
      setState(() {
        _habitos = pagina.content;
        _page = pagina.page ?? 0;
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? pagina.content.length;
        _fetchedAt = DateTime.now();
        _loading = false;
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
      final pagina = await ref.read(_repoProvider).meusHabitosPagina(
        page: _page + 1,
        q: _query,
      );
      if (!mounted) return;
      final seen = _habitos.map((h) => h.id).toSet();
      setState(() {
        _habitos = [
          ..._habitos,
          ...pagina.content.where((h) => seen.add(h.id)),
        ];
        _page = pagina.page ?? (_page + 1);
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _habitos.length;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _toggle(Habito h) async {
    try {
      final result = await ref.read(_repoProvider).toggleHoje(h.id);
      setState(() {
        _habitos = _habitos
            .map(
              (x) => x.id == h.id
                  ? Habito(
                      id: x.id,
                      titulo: x.titulo,
                      descricao: x.descricao,
                      icone: x.icone,
                      tipo: x.tipo,
                      metaDiaria: x.metaDiaria,
                      metaSemanal: x.metaSemanal,
                      feitosNaSemana: result.feito
                          ? x.feitosNaSemana + 1
                          : (x.feitosNaSemana - 1).clamp(0, 7),
                      feitoHoje: result.feito,
                      streakAtual: result.streak,
                      badgeSemana: result.streak >= 7,
                      alunoId: x.alunoId,
                    )
                  : x,
            )
            .toList();
      });
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
      label: 'Meus hábitos',
      child: FeatureGate(
        featureName: 'Habit Coaching',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'habitCoaching',
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
          child: FxKeyboardDismissScope(
            child: FxShellScaffold(
              useMesh: true,
              constrainWidth: false,
              appBar: FxShellAppBar(
                title: 'Meus hábitos',
                subtitle: FxHubFreshness.joinCount(
                  habitoCountLabel(_loading ? 0 : _total),
                  _loading ? null : freshnessLabel,
                ),
                onBack: () {
                  FxKeyboardDismissScope.dismiss();
                  safePopOrGo(context, '/dashboard/aluno');
                },
                actions: [
                  FxHelpIconButton(
                    tooltip: 'Como usar os hábitos',
                    onTap: () => showFxHelpSheet(
                      context,
                      title: 'Hábitos',
                      subtitle: 'Metas diárias que seu personal cadastrou.',
                      tips: const [
                        FxHelpTip('Como calculamos', habitoComoCalculamos),
                        FxHelpTip(
                          'Marcar',
                          'O checkbox marca o check de hoje. Toque no hábito abre o detalhe.',
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
                      title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      message: _error!,
                      onRetry: _carregar,
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
                              hintText: 'Buscar hábito',
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildList(bool searching) {
    return RefreshIndicator(
      onRefresh: _carregar,
      child: _habitos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const SizedBox(height: 48),
                FxEmptyState(
                  icon: searching ? 'search' : 'dumbbell',
                  title: searching
                      ? 'Nenhum hábito encontrado'
                      : 'Nenhum hábito ainda',
                  subtitle: searching
                      ? 'Tente outro nome. O personal cadastra os hábitos da sua rotina.'
                      : 'Seu personal ainda não cadastrou hábitos. Avise no chat para começar.',
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
              itemCount: _habitos.length + (_hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _habitos.length) {
                  return FxSatelliteListTile(
                    title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                    onTap: _loadingMore ? null : _carregarMais,
                  );
                }
                final h = _habitos[i];
                return FxSatelliteListTile(
                  title: h.titulo,
                  subtitle: Text(
                    habitoAlunoSubtitle(
                      descricao: h.descricao,
                      feitosNaSemana: h.feitosNaSemana,
                      metaSemanal: h.metaSemanal,
                    ),
                  ),
                  trailing: Text(
                    '${h.streakAtual}d',
                    style: TextStyle(
                      color: EagleTokens.warn,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  leading: Semantics(
                    label: h.feitoHoje
                        ? 'Desmarcar hábito ${h.titulo}'
                        : 'Marcar hábito ${h.titulo}',
                    child: Checkbox(
                      value: h.feitoHoje,
                      onChanged: (_) => _toggle(h),
                    ),
                  ),
                  onTap: () async {
                    await context.push(habitoAlunoDetailPath(h.id), extra: h);
                    if (mounted) await _carregar();
                  },
                );
              },
            ),
    );
  }
}
