import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/a11y_announce.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../anamnese/widgets/anamnese_status_banner.dart';
import '../../checkin/data/meus_treinos_mem_cache.dart';
import '../../coach/data/coach_proativo_repository.dart';
import '../../coach/widgets/coach_proativo_card.dart';
import '../../health/widgets/aluno_recovery_card.dart';
import '../../monetizacao/widgets/aluno_upsell_carousel.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../../nps/widgets/nps_prompt_dialog.dart';
import '../data/aluno_home_anamnese.dart';
import '../data/aluno_home_insight.dart';
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
import '../widgets/aluno_home_insight_line.dart';
import '../widgets/aluno_home_skeleton.dart';
import '../widgets/aluno_pendencias_block.dart';
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
  var _npsPrompted = false;
  var _viewTracked = false;

  /// Null até ler as prefs: a pendência de agenda fica fora até lá, sem
  /// piscar nem mandar VIEWED de algo já resolvido.
  bool? _agendaReviewed;
  (AlunoDashboardHomeBundle, bool?, AlunoHomeView)? _viewMemo;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAgendaReviewed());
    ref.listenManual(
      alunoDashboardHomeProvider,
      (_, next) => next.whenData(_onHomeLoaded),
      fireImmediately: true,
    );
  }

  AlunoHomeView _viewFor(AlunoDashboardHomeBundle home) {
    final memo = _viewMemo;
    if (memo != null &&
        identical(memo.$1, home) &&
        memo.$2 == _agendaReviewed) {
      return memo.$3;
    }
    final view = buildAlunoHomeView(
      home,
      agendaReviewed: _agendaReviewed ?? true,
    );
    _viewMemo = (home, _agendaReviewed, view);
    return view;
  }

  /// NPS só com o treino do dia feito: é o `POS_TREINO` que o backend grava,
  /// e não interrompe quem abriu a Home para treinar.
  void _onHomeLoaded(AlunoDashboardHomeBundle home) {
    MeusTreinosMemCache.save(home.treinos);
    _syncAnalytics(home);
    if (!home.npsDeveResponder || _npsPrompted) return;
    if (_viewFor(home).action.mode != AlunoTodayMode.workoutDone) return;
    _npsPrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAlunoNpsPrompt(context, ref);
    });
  }

  Future<void> _loadAgendaReviewed() async {
    final reviewed = await isAlunoAgendaReviewed();
    if (!mounted) return;
    setState(() => _agendaReviewed = reviewed);
    final home = ref.read(alunoDashboardHomeProvider).value;
    if (home != null) _syncAnalytics(home);
  }

  /// Espera a agenda ser lida: antes disso as pendências ainda não são finais.
  void _syncAnalytics(AlunoDashboardHomeBundle home) {
    if (_agendaReviewed == null) return;
    final view = _viewFor(home);
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
      ),
    );
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
    unawaited(context.push(p.tipo.route).then((_) => _loadAgendaReviewed()));
  }

  void _pendenciaShown(AlunoPendencia p) {
    AlunoAutonomyAnalytics.viewed(
      ref.read(alunoRepositoryProvider),
      AlunoAutonomyAnalytics.forPendencia(p),
    );
  }

  Future<void> _refresh() async {
    invalidateAlunoDashboardHome(ref);
    await Future.wait([
      ref.read(alunoDashboardHomeProvider.future),
      _loadAgendaReviewed(),
    ]);
    if (!mounted) return;
    fxAnnounce(context, S.of(context).alunoHomeAtualizado);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final homeAsync = ref.watch(alunoDashboardHomeProvider);

    return fxScreenA11yScope(
      label: s.alunoHomeTitulo,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: s.alunoHomeTitulo,
          subtitle: homeAsync.when(
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
          loading: () => const AlunoHomeSkeleton(),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(alunoDashboardHomeProvider),
              ),
          data: (home) => _buildHome(context, home, isDark),
        ),
      ),
    );
  }

  Widget _buildHome(
    BuildContext context,
    AlunoDashboardHomeBundle home,
    bool isDark,
  ) {
    final view = _viewFor(home);
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
        _TodayFocusCard(
          action: action,
          insight: view.insight,
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
          ),
        ),
      if (view.semanaVisivel)
        (TokensStrip.s4, AlunoWeekSummaryCard(summary: view.semana)),
      if (view.prontidaoVisivel)
        (
          view.semanaVisivel ? TokensStrip.s3 : TokensStrip.s4,
          AlunoRecoveryCard(snapshot: home.recovery),
        ),
      if (view.jaTreinou)
        (
          TokensStrip.s4,
          AlunoEvolutionCard(
            volumePorSemana: home.volumePorSemana,
            forcaPorSemana: home.forcaPorSemana,
            forcaDeltaPercent: home.forcaDeltaPercent,
            ultimoRecorde: home.recordes.isEmpty ? null : home.recordes.first,
            recordeRecente: view.recordeRecente,
          ),
        ),
      if (view.pendencias.isNotEmpty)
        (
          TokensStrip.s4,
          AlunoPendenciasBlock(
            pendencias: view.pendencias,
            onTap: _openPendencia,
            onShown: _pendenciaShown,
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
