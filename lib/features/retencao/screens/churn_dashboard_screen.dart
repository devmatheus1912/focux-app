import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/retencao_repository.dart';
import '../utils/retencao_display.dart';
import '../utils/retencao_fila.dart';
import '../widgets/retencao_acoes_sheet.dart';

part 'churn_dashboard_screen_cards.part.dart';
part 'churn_dashboard_screen_content.part.dart';

final retencaoRepositoryProvider = Provider(
  (ref) => RetencaoRepository(ref.read(apiClientProvider)),
);

/// Alunos em risco: quem pode parar de treinar e o que fazer agora.
class ChurnDashboardScreen extends ConsumerStatefulWidget {
  const ChurnDashboardScreen({super.key});

  @override
  ConsumerState<ChurnDashboardScreen> createState() =>
      _ChurnDashboardScreenState();
}

class _ChurnDashboardScreenState extends ConsumerState<ChurnDashboardScreen> {
  RetencaoHome? _home;
  List<RetencaoAlunoScore> _base = [];
  var _page = 0;
  var _hasNext = false;
  var _carregandoMais = false;
  bool _loading = true;
  String? _error;
  RetencaoNivel? _nivel;
  var _query = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final _scroll = ScrollController();
  final _openedAt = DateTime.now();
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _carregarMais();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.retencaoHubViewed,
      props: {'alto': _home?.alto ?? 0, 'medio': _home?.medio ?? 0},
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.retencaoHubTtv,
        props: {'ms': DateTime.now().difference(_openedAt).inMilliseconds},
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(retencaoRepositoryProvider);
      final home = await repo.getHome();
      final base = await repo.listarBase(q: _query);
      if (!mounted) return;
      setState(() {
        _home = home;
        _base = base.itens;
        _page = base.page;
        _hasNext = base.hasNext;
        _loading = false;
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasNext) return;
    setState(() => _carregandoMais = true);
    try {
      final next = await ref
          .read(retencaoRepositoryProvider)
          .listarBase(page: _page + 1, q: _query);
      if (!mounted) return;
      final vistos = _base.map((s) => s.alunoId).toSet();
      setState(() {
        _base = [..._base, ...next.itens.where((s) => vistos.add(s.alunoId))];
        _page = next.page;
        _hasNext = next.hasNext;
        _carregandoMais = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  void _onBusca(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final q = value.trim();
      if (q == _query) return;
      _query = q;
      _recarregarBase();
    });
  }

  Future<void> _recarregarBase() async {
    try {
      final base = await ref
          .read(retencaoRepositoryProvider)
          .listarBase(q: _query);
      if (!mounted) return;
      setState(() {
        _base = base.itens;
        _page = base.page;
        _hasNext = base.hasNext;
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  void _abrirAluno(RetencaoAlunoScore score) {
    AnalyticsService.instance.track(
      ProductEvents.alertaRiscoOpened,
      props: {'alunoId': score.alunoId},
    );
    context.push('/alunos/${score.alunoId}');
  }

  void _abrirChat(RetencaoAlunoScore score) {
    AnalyticsService.instance.track(
      ProductEvents.chatThreadOpened,
      props: {'alunoId': score.alunoId},
    );
    context.push('/alunos/${score.alunoId}/chat', extra: score.alunoNome);
  }

  void _abrirCobranca(RetencaoAlunoScore score) {
    AnalyticsService.instance.track(ProductEvents.financeiroViewed);
    context.push('/financeiro?alunoId=${score.alunoId}');
  }

  void _abrirAcoes(RetencaoAlunoScore score) {
    showRetencaoAcoesSheet(
      context,
      score: score,
      onAluno: () => _abrirAluno(score),
      onChat: () => _abrirChat(score),
      onCobrar: () => _abrirCobranca(score),
    );
  }

  void _ajuda() {
    final s = S.of(context);
    AnalyticsService.instance.track(ProductEvents.retencaoHubHelpOpened);
    showFxHelpSheet(
      context,
      title: s.retencaoTitulo,
      subtitle: s.retencaoAjudaSub,
      tips: [
        FxHelpTip(s.retencaoAjudaSaudeTitulo, s.retencaoAjudaSaudeTexto),
        FxHelpTip(s.retencaoAjudaFilaTitulo, s.retencaoAjudaFilaTexto),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final home = _home;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(home?.fetchedAt);

    return fxScreenA11yScope(
      label: FocuxMicrocopy.alunosEmRisco,
      child: FxKeyboardPopScope(
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: s.retencaoTitulo,
            subtitle: freshnessLabel ?? s.retencaoSubtitulo,
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/dashboard/personal');
            },
            actions: [
              FxHelpIconButton(tooltip: retencaoComoUsar, onTap: _ajuda),
            ],
          ),
          body:
              _loading
                  ? const SkeletonList(count: 6)
                  : _error != null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: _error!,
                    onRetry: _load,
                  )
                  : RefreshIndicator(
                    color: primary,
                    onRefresh: () async {
                      AnalyticsService.instance.track(
                        ProductEvents.retencaoHubRefreshed,
                      );
                      await _load();
                    },
                    child:
                        home == null || home.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 48),
                                FxEmptyState(
                                  icon: 'activity',
                                  title: retencaoEmptyTitle,
                                  subtitle: retencaoEmptySubtitle,
                                  action: FxEmptyAction(
                                    label: retencaoFocusActionLabel(
                                      RetencaoFocusActionId.verAlunos,
                                    ),
                                    onTap: () {
                                      AnalyticsService.instance.track(
                                        ProductEvents.alunosViewed,
                                      );
                                      goPersonalShellTab(context, '/alunos');
                                    },
                                  ),
                                ),
                              ],
                            )
                            : _conteudo(context, home),
                  ),
        ),
      ),
    );
  }
}
