import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
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
      _loading = _home == null;
      _error = null;
    });
    try {
      final repo = ref.read(retencaoRepositoryProvider);
      final baseFutura = repo.listarBase(q: _query, nivel: _nivel?.api);
      final home = await repo.getHome();
      final base = await baseFutura;
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
      setState(() => _loading = false);
      _falhou(e);
    }
  }

  /// Com a lista na tela, avisa e mantém; sem nada para mostrar, vira tela de erro.
  void _falhou(Object e) {
    if (_home == null) {
      setState(() => _error = friendlyError(e));
    } else {
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasNext) return;
    setState(() => _carregandoMais = true);
    try {
      final next = await ref
          .read(retencaoRepositoryProvider)
          .listarBase(page: _page + 1, q: _query, nivel: _nivel?.api);
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
          .listarBase(q: _query, nivel: _nivel?.api);
      if (!mounted) return;
      setState(() {
        _base = base.itens;
        _page = base.page;
        _hasNext = base.hasNext;
      });
    } catch (e) {
      if (mounted) _falhou(e);
    }
  }

  void _filtrar(RetencaoNivel? nivel) {
    setState(() => _nivel = nivel == _nivel ? null : nivel);
    _recarregarBase();
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

  Future<void> _abrirAcoes(RetencaoAlunoScore score) async {
    final acao = await showRetencaoAcoesSheet(context, score: score);
    if (!mounted) return;
    switch (acao) {
      case RetencaoAcao.mensagem:
        _abrirChat(score);
      case RetencaoAcao.perfil:
        _abrirAluno(score);
      case RetencaoAcao.ficha:
        context.push('/alunos/${score.alunoId}');
      case RetencaoAcao.cobrar:
        _abrirCobranca(score);
      case RetencaoAcao.adiar:
        await _adiar(score);
      case null:
        break;
    }
  }

  Future<void> _adiar(RetencaoAlunoScore score) async {
    try {
      await ref.read(retencaoRepositoryProvider).adiar(score.alunoId);
      await _load();
    } catch (e) {
      if (mounted) _falhou(e);
    }
  }

  Future<void> _maisAcoes() async {
    final s = S.of(context);
    final rota = await showFxGroupedActionSheet<String>(
      context,
      titulo: s.retencaoTitulo,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: '/winback',
            rotulo: s.retencaoEntradaHistorico,
            descricao: s.retencaoEntradaHistoricoSub,
            icone: Icons.notifications_none_rounded,
          ),
          FxActionItem(
            valor: '/dunning',
            rotulo: s.retencaoEntradaCobranca,
            descricao: s.retencaoEntradaCobrancaSub,
            icone: Icons.repeat_rounded,
          ),
        ]),
      ],
    );
    if (rota != null && mounted) context.push(rota);
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
              FxHelpIconButton(tooltip: s.retencaoComoUsar, onTap: _ajuda),
              IconButton(
                tooltip: s.retencaoMaisAcoes,
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: _maisAcoes,
              ),
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
                                  title: s.retencaoVazioTitulo,
                                  subtitle: s.retencaoVazioTexto,
                                  action: FxEmptyAction(
                                    label: s.retencaoVerAlunos,
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
