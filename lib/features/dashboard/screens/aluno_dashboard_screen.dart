import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/a11y_announce.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_status_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../checkin/data/meus_treinos_mem_cache.dart';
import '../../coach/data/coach_proativo_repository.dart';
import '../../coach/widgets/coach_proativo_card.dart';
import '../../health/widgets/aluno_recovery_card.dart';
import '../../monetizacao/widgets/aluno_upsell_carousel.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../../nps/widgets/nps_prompt_dialog.dart';
import '../data/aluno_home_anamnese.dart';
import '../data/aluno_onboarding_prefs.dart';
import '../data/dashboard_repository.dart';
import '../providers/dashboard_provider.dart';
import '../utils/aluno_autonomy_analytics.dart';
import '../utils/aluno_home_analytics.dart';
import '../utils/aluno_home_texts.dart';
import '../utils/aluno_home_view.dart';
import '../utils/aluno_pendencias.dart';
import '../utils/aluno_today_action.dart';
import '../widgets/aluno_evolution_card.dart';
import '../widgets/aluno_home_header.dart';
import '../widgets/aluno_home_skeleton.dart';
import '../widgets/aluno_pendencias_block.dart';
import '../widgets/aluno_today_focus_card.dart';
import '../widgets/aluno_week_summary_card.dart';
import '../widgets/dashboard_section_header.dart';

part 'aluno_dashboard_screen_header.part.dart';
part 'aluno_dashboard_screen_tools.part.dart';

class AlunoDashboardScreen extends ConsumerStatefulWidget {
  const AlunoDashboardScreen({super.key});

  @override
  ConsumerState<AlunoDashboardScreen> createState() =>
      _AlunoDashboardScreenState();
}

class _AlunoDashboardScreenState extends ConsumerState<AlunoDashboardScreen> {
  var _npsPendente = false;
  var _npsPrompted = false;
  var _viewTracked = false;
  var _naFrente = true;
  GoRouterDelegate? _router;

  /// Null até ler as prefs: a pendência de agenda fica fora até lá, sem
  /// piscar nem mandar VIEWED de algo já resolvido.
  ({String? inicio})? _agendaVista;
  ({
    AlunoDashboardHomeBundle home,
    ({String? inicio})? vista,
    DateTime validaAte,
    AlunoHomeView view,
  })?
  _viewMemo;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAgendaVista());
    ref.listenManual(
      alunoDashboardHomeProvider,
      (_, next) => next.whenData(_onHomeLoaded),
      fireImmediately: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context).routerDelegate;
    if (identical(router, _router)) return;
    _router?.removeListener(_onRota);
    _router = router..addListener(_onRota);
  }

  @override
  void dispose() {
    _router?.removeListener(_onRota);
    _relogio?.cancel();
    super.dispose();
  }

  bool get _homeNaFrente =>
      _router?.currentConfiguration.uri.path == alunoHomeRoute;

  /// A agenda pode ter sido aberta por outro caminho (catálogo, notificação):
  /// ao voltar para a Home, relê o que o aluno já viu.
  void _onRota() {
    final naFrente = _homeNaFrente;
    if (naFrente && !_naFrente) unawaited(_loadAgendaVista());
    _naFrente = naFrente;
    _agendarNps();
  }

  /// Memo até [alunoHomeViewValidaAte]: com a Home aberta, o horário que passa
  /// e a virada do dia redesenham a tela sem esperar outro rebuild.
  AlunoHomeView _viewFor(AlunoDashboardHomeBundle home, DateTime now) {
    final memo = _viewMemo;
    final vista = _agendaVista;
    if (memo != null &&
        identical(memo.home, home) &&
        memo.vista == vista &&
        now.isBefore(memo.validaAte)) {
      return memo.view;
    }
    final view = buildAlunoHomeView(
      home,
      now: now,
      agendaReviewed:
          vista == null ||
          alunoAgendaVista(vista.inicio, home.agendaProximoInicio),
    );
    final validaAte = alunoHomeViewValidaAte(view, now);
    _viewMemo = (home: home, vista: vista, validaAte: validaAte, view: view);
    _agendarRelogio(validaAte.difference(now));
    return view;
  }

  void _agendarRelogio(Duration ate) {
    _relogio?.cancel();
    // Margem: o rebuild tem que cair depois do limite, senão o memo ainda vale.
    _relogio = Timer(ate + const Duration(seconds: 1), () {
      if (mounted) setState(() {});
    });
  }

  /// NPS só com o treino do dia feito: é o `POS_TREINO` que o backend grava,
  /// e não interrompe quem abriu a Home para treinar.
  void _onHomeLoaded(AlunoDashboardHomeBundle home) {
    MeusTreinosMemCache.save(home.treinos);
    _syncAnalytics(home);
    _npsPendente =
        home.npsDeveResponder &&
        _viewFor(home, DateTime.now()).action.mode ==
            AlunoTodayMode.workoutDone;
    _agendarNps();
  }

  void _agendarNps() {
    if (!_npsPendente || _npsPrompted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tentarNps());
  }

  /// Ao concluir o treino a Home recarrega por baixo da celebração: a pergunta
  /// espera a Home voltar para a frente, senão o pop do check-in a fecharia.
  void _tentarNps() {
    if (!mounted || !_npsPendente || _npsPrompted || !_homeNaFrente) return;
    _npsPrompted = true;
    showAlunoNpsPrompt(context, ref);
  }

  Future<void> _loadAgendaVista() async {
    final inicio = await readAlunoAgendaVista();
    if (!mounted) return;
    final atual = _agendaVista;
    if (atual != null && atual.inicio == inicio) return;
    setState(() => _agendaVista = (inicio: inicio));
    final home = ref.read(alunoDashboardHomeProvider).value;
    if (home != null) _syncAnalytics(home);
  }

  /// Espera a agenda ser lida: antes disso as pendências ainda não são finais.
  void _syncAnalytics(AlunoDashboardHomeBundle home) {
    if (_agendaVista == null) return;
    final view = _viewFor(home, DateTime.now());
    _completeResolvedTasks(view);
    if (_viewTracked) return;
    _viewTracked = true;
    AlunoHomeAnalytics.viewed(
      action: view.action,
      pendencias: view.pendencias.length,
      aviso: view.aviso,
    );
  }

  void _completeResolvedTasks(AlunoHomeView view) {
    AlunoAutonomyAnalytics.completeResolved(
      ref.read(alunoRepositoryProvider),
      alunoAutonomyOpenTaskIds(
        action: view.action,
        pendenciasAbertas: view.pendenciasAbertas,
        financeiroEmAtraso: view.financeiroEmAtraso,
      ),
    );
  }

  void _openFinanceiro() {
    AlunoAutonomyAnalytics.clicked(
      ref.read(alunoRepositoryProvider),
      AlunoAutonomyAnalytics.financeiro,
    );
    context.push(alunoFinanceiroRoute);
  }

  void _openToday(AlunoTodayAction action) {
    AlunoHomeAnalytics.focusAction(action);
    final task = AlunoAutonomyAnalytics.forToday(action);
    if (task != null) {
      AlunoAutonomyAnalytics.clicked(ref.read(alunoRepositoryProvider), task);
    }
    context.push(action.route, extra: action.routeExtra);
  }

  void _openPendencia(AlunoPendencia p) {
    AlunoAutonomyAnalytics.clicked(
      ref.read(alunoRepositoryProvider),
      AlunoAutonomyAnalytics.forPendencia(p),
    );
    context.push(p.tipo.route);
  }

  void _pendenciaShown(AlunoPendencia p) {
    AlunoAutonomyAnalytics.viewed(
      ref.read(alunoRepositoryProvider),
      AlunoAutonomyAnalytics.forPendencia(p),
    );
  }

  Future<void> _refresh() async {
    final s = S.of(context);
    try {
      await Future.wait([refreshAlunoDashboardHome(ref), _loadAgendaVista()]);
    } catch (_) {
      if (mounted) FeedbackHelper.showError(context, s.alunoHomeAtualizarErro);
      return;
    }
    if (!mounted) return;
    fxAnnounce(context, s.alunoHomeAtualizado);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final homeAsync = ref.watch(alunoDashboardHomeProvider);
    final now = DateTime.now();

    return fxScreenA11yScope(
      label: s.alunoHomeTitulo,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: s.alunoHomeTitulo,
          subtitle: homeAsync.when(
            skipLoadingOnReload: true,
            skipError: true,
            data: (home) => FxHubFreshness.fromFetchedAt(home.fetchedAt),
            loading: () => null,
            error: (_, __) => null,
          ),
          showBack: false,
          actions: [
            FxHelpIconButton(
              tooltip: s.alunoHomeAjudaTooltip,
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: s.alunoHomeTitulo,
                    subtitle: s.alunoHomeAjudaSubtitulo,
                    tips: [
                      FxHelpTip(
                        s.alunoHomeAjudaCalculoTitulo,
                        s.alunoHomeAjudaCalculo,
                      ),
                      FxHelpTip(
                        s.alunoHomeAjudaFocoTitulo,
                        s.alunoHomeAjudaFoco,
                      ),
                      FxHelpTip(
                        s.alunoHomeAjudaPendenciasTitulo,
                        s.alunoHomeAjudaPendencias,
                      ),
                      FxHelpTip(
                        s.alunoHomeAjudaMaisTitulo,
                        s.alunoHomeAjudaMais,
                      ),
                    ],
                  ),
            ),
            NotificacaoBadgeButton(
              size: FxHelpChrome.iconSize,
              countOverride: ref.watch(alunoHomeNotificacoesSelectProvider),
            ),
            const SizedBox(width: TokensStrip.s2),
          ],
        ),
        body: homeAsync.when(
          skipLoadingOnReload: true,
          skipError: true,
          loading: () => const AlunoHomeSkeleton(),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(alunoDashboardHomeProvider),
              ),
          data: (home) => _buildHome(context, home, isDark, now),
        ),
      ),
    );
  }

  Widget _buildHome(
    BuildContext context,
    AlunoDashboardHomeBundle home,
    bool isDark,
    DateTime now,
  ) {
    final view = _viewFor(home, now);
    final action = view.action;

    // (espaço antes, bloco): só entra bloco com conteúdo, então nenhum
    // espaçamento se soma quando um bloco some.
    final blocos = <(double, Widget)>[
      (
        0,
        AlunoHomeHeader(
          alunoNome: home.aluno.nome,
          nomePersonal: home.personalBrand.nomePersonal,
          logoUrl: home.personalBrand.logoUrl,
          onOpenChat: () => context.push('/chat/aluno'),
        ),
      ),
      (
        TokensStrip.s2,
        AlunoTodayFocusCard(
          action: action,
          hoje: now,
          insight: view.insight,
          horario: view.horarioNoFoco,
          prontidaoBaixa: view.prontidaoBaixa,
          isDark: isDark,
          onAction: () => _openToday(action),
        ),
      ),
      if (view.aviso != AlunoHomeAviso.nenhum)
        (
          TokensStrip.s3,
          _AlunoHomeAviso(
            aviso: view.aviso,
            anamnese: home.anamnesePendente,
            coachMensagens: view.coach,
            onFinanceiro: _openFinanceiro,
          ),
        ),
      if (view.pendencias.isNotEmpty)
        (
          TokensStrip.s4,
          AlunoPendenciasBlock(
            pendencias: view.pendencias,
            hoje: now,
            onTap: _openPendencia,
            onShown: _pendenciaShown,
          ),
        ),
      if (view.semanaVisivel)
        (TokensStrip.s4, AlunoWeekSummaryCard(summary: view.semana)),
      if (view.prontidaoVisivel)
        (
          view.semanaVisivel ? TokensStrip.s3 : TokensStrip.s4,
          AlunoRecoveryCard(
            snapshot: home.recovery,
            mostrarDica: !view.prontidaoBaixa,
          ),
        ),
      if (view.jaTreinou)
        (
          TokensStrip.s4,
          AlunoEvolutionCard(
            forcaPorSemana: home.forcaPorSemana,
            forcaDeltaPercent: home.forcaDeltaPercent,
            ultimoRecorde: home.recordes.isEmpty ? null : home.recordes.first,
            recordeRecente: view.recordeRecente,
          ),
        ),
      if (view.ofertas.isNotEmpty)
        (TokensStrip.s4, AlunoUpsellCarousel(ofertas: view.ofertas)),
      (
        TokensStrip.s4,
        _StudentToolsSection(
          atalhos: view.atalhos,
          recursosIndisponiveis: view.recursosIndisponiveis,
        ),
      ),
    ];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FxContentWidthLimiter(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (espaco, bloco) in blocos) ...[
                if (espaco > 0) SizedBox(height: espaco),
                bloco,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
