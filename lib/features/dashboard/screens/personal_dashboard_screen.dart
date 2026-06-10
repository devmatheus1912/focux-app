import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/fx_utils.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/aderencia_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../notificacoes/data/notificacoes_repository.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../subscription/widgets/plan_usage_banner.dart';
import '../../subscription/widgets/trial_countdown_banner.dart';
import '../../subscription/widgets/dashboard_activation_cta.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../utils/dashboard_day_focus.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_sparkline_helpers.dart';
import '../widgets/dashboard_day_focus_banner.dart';
import '../widgets/dashboard_attention_card.dart';
import '../widgets/dashboard_collapsible_section.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_screen_helpers.dart';
import '../widgets/dashboard_horizontal_scroll_peek.dart';
import '../widgets/dashboard_header_profile_avatar.dart';
import '../widgets/dashboard_financial_hero_section.dart';
import '../widgets/dashboard_shimmer_loading.dart';
import '../widgets/dashboard_pulse_strip.dart';
import '../widgets/dashboard_tools_section.dart';
import '../widgets/dashboard_command_center_section.dart';
import '../widgets/dashboard_command_center_sticky_header.dart';
import '../widgets/dashboard_aderencia_semana_widget.dart';
import '../widgets/dashboard_error_state.dart';
class PersonalDashboardScreen extends ConsumerStatefulWidget {
  const PersonalDashboardScreen({super.key});

  @override
  ConsumerState<PersonalDashboardScreen> createState() =>
      _PersonalDashboardScreenState();
}
/// Scroll offset until which the floating priorities chip stays visible (sticky takes over after).
const _commandCenterPrioritiesFloatingMaxOffset = 220;

class _PersonalDashboardScreenState
    extends ConsumerState<PersonalDashboardScreen>
    with TickerProviderStateMixin {
  FinanceiroDashboard? _finData;
  bool _loadingFin = true;
  double _homeScrollOffset = 0;
  late final ScrollController _homeScrollController;
  int _attentionSectionResetToken = 0;
  String? _lastTrackedLocation;
  VoidCallback? _routeListener;
  RouteInformationProvider? _routeInformationProvider;
  bool _motionConfigured = false;

  late AnimationController _gradientCtrl;
  late AnimationController _counterCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _counterAnim;
  late Animation<double> _heroFade;
  late Animation<double> _kpiFade;
  late Animation<double> _commandFade;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _counterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _counterAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _heroFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.32, 0.78, curve: Curves.easeOutCubic),
    );
    _kpiFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.48, 0.92, curve: Curves.easeOutCubic),
    );
    _commandFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.08, 0.58, curve: Curves.easeOutCubic),
    );
    _homeScrollController = ScrollController();
    _homeScrollController.addListener(_onHomeScroll);
    _loadFinFromHome();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboardingWizard();
      _bindDashboardReturnListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (TokensStrip.prefersReducedMotion(context)) {
      _gradientCtrl.stop();
      _entryCtrl.value = 1.0;
    } else {
      _gradientCtrl.repeat();
      _entryCtrl.forward(from: 0);
    }
  }

  bool _showsFloatingPrioritiesChip(double offset) =>
      offset >= 80 && offset < _commandCenterPrioritiesFloatingMaxOffset;

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    final offset = _homeScrollController.offset;
    if ((offset - _homeScrollOffset).abs() < 2) return;
    final wasFloating = _showsFloatingPrioritiesChip(_homeScrollOffset);
    final nowFloating = _showsFloatingPrioritiesChip(offset);
    final wasStickyChip = _homeScrollOffset >= 80;
    final nowStickyChip = offset >= 80;
    _homeScrollOffset = offset;
    if (wasFloating != nowFloating || wasStickyChip != nowStickyChip) {
      setState(() {});
    }
  }

  void _bindDashboardReturnListener() {
    if (!mounted || _routeListener != null) return;
    final router = GoRouter.of(context);
    _lastTrackedLocation = router.routeInformationProvider.value.uri.path;
    _routeInformationProvider = router.routeInformationProvider;
    _routeListener = () {
      final path = _routeInformationProvider!.value.uri.path;
      if (_lastTrackedLocation != null &&
          path == '/dashboard/personal' &&
          _lastTrackedLocation != '/dashboard/personal') {
        setState(() => _attentionSectionResetToken++);
      }
      _lastTrackedLocation = path;
    };
    router.routeInformationProvider.addListener(_routeListener!);
  }

  Future<void> _maybeShowOnboardingWizard() async {
    try {
      final w = await OnboardingRepository(ref.read(apiClientProvider)).wizard();
      if (!mounted || w.wizardCompleto) return;
      if (w.progressPercent >= 100) return;
      context.push('/onboarding/wizard');
    } catch (_) {}
  }

  @override
  void dispose() {
    final listener = _routeListener;
    final provider = _routeInformationProvider;
    if (listener != null && provider != null) {
      provider.removeListener(listener);
    }
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    _gradientCtrl.dispose();
    _counterCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFinFromHome() async {
    if (mounted) {
      setState(() {
        _loadingFin = true;
      });
    }
    try {
      final home = await ref.read(dashboardHomeProvider.future);
      if (!mounted) return;
      _applyFinanceData(home.financeiro);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingFin = false;
        });
        FeedbackHelper.showWarn(context, friendlyError(e));
      }
    }
  }

  void _applyFinanceData(FinanceiroDashboard data) {
    if (!mounted) return;
    setState(() {
      _finData = data;
      _loadingFin = false;
    });
    _counterAnim = Tween<double>(
      begin: 0,
      end: data.receitaMes,
    ).animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    if (TokensStrip.prefersReducedMotion(context)) {
      _counterCtrl.value = 1.0;
    } else {
      _counterCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heroPrimary = BrandPalette.softened(primary, amount: 0.06);
    final heroDeep = BrandPalette.deep(heroPrimary);
    final homeAsync = ref.watch(dashboardHomeProvider);
    final commandAsync = ref.watch(commandCenterProvider);
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final themeDark = Theme.of(context).brightness == Brightness.dark;
    final alunosAsync = ref.watch(alunosProvider);
    final historicoCheckinsAsync = ref.watch(historicoCheckinProvider);
    final chromeOnDark = themeDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: homeAsync.when(
          loading: () => DashboardShimmerLoading(themeDark: themeDark),
          error:
              (e, _) => DashboardErrorState(
                chromeOnDark: chromeOnDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () {
                  ref.invalidate(dashboardHomeProvider);
                  ref.invalidate(alunosProvider);
                  _loadFinFromHome();
                },
              ),
          data: (home) {
              final data = home.personal;
              final screenWidth = MediaQuery.sizeOf(context).width;
              final isCompactPhone = screenWidth < 390;
              final shortcutAspectRatio = isCompactPhone ? 2.75 : 3.05;

              // Computed values for hero card
              final monthNames = [
                'janeiro',
                'fevereiro',
                'março',
                'abril',
                'maio',
                'junho',
                'julho',
                'agosto',
                'setembro',
                'outubro',
                'novembro',
                'dezembro',
              ];
              final mes = monthNames[DateTime.now().month - 1];
              final pendente = ((_finData?.previsaoReceita ?? 0) -
                      (_finData?.receitaMes ?? 0))
                  .clamp(0.0, double.infinity);
              final metaReceita = _finData?.previsaoReceita ?? 0;
              final receitaAtual = _finData?.receitaMes ?? 0;
              final progressRaw =
                  metaReceita > 0 ? receitaAtual / metaReceita : 0.0;
              final metaSuperada = metaReceita > 0 && receitaAtual >= metaReceita;

              final alunosAtivos = alunosAsync.maybeWhen(
                data:
                    (alunos) => alunos.where((a) => a.status == 'ATIVO').length,
                orElse: () => data.alunosAtivos,
              );
              final riscoAlto = alunosAsync.maybeWhen(
                data: (alunos) => alunos.where((a) => a.emRisco).length,
                orElse: () => 0,
              );
              final alunosEmRisco = alunosAsync.maybeWhen(
                data: (alunos) => alunos.where((a) => a.emRisco).toList(),
                orElse: () => const <Aluno>[],
              );

              final hoje = DateTime.now();
              final checkinsHoje = historicoCheckinsAsync.maybeWhen(
                data: (items) {
                  bool sameDay(DateTime a, DateTime b) =>
                      a.year == b.year && a.month == b.month && a.day == b.day;
                  return items.where((e) {
                    final concluded = DateTime.tryParse(e.concluidoEm ?? '');
                    if (concluded == null) return false;
                    return sameDay(concluded.toLocal(), hoje);
                  }).length;
                },
                orElse: () => 0,
              );
              final checkinsTrend = historicoCheckinsAsync.maybeWhen(
                data: (items) => dashboardCheckinsSparklineUltimos7Dias(items),
                orElse: () => List<double>.filled(7, 0),
              );
              final receitaTrend = dashboardReceitaSparklineMensal(
                _finData?.evolucaoMensal ?? const [],
              );
              final agendaHoje = commandAsync.maybeWhen(
                data: (cc) => cc.agendaHoje.length,
                orElse: () => 0,
              );
              final attentionVisible = alunosEmRisco.isNotEmpty ||
                  (_finData != null &&
                      _finData!.vencimentosProximos.isNotEmpty);
              final onboardingAsync = ref.watch(onboardingStatusProvider);
              final onboardingIncomplete = onboardingAsync.maybeWhen(
                data: (s) => !s.ativacaoCompleta,
                orElse: () => false,
              );
              final primeiroTreinoCriado = onboardingAsync.maybeWhen(
                data: (s) => s.primeiroTreinoCriado,
                orElse: () => false,
              );
              final riskDominante =
                  alunosAtivos > 0 &&
                  riscoAlto >= math.max(2, (alunosAtivos * 0.5).ceil());
              final vencimentosCount =
                  _finData?.vencimentosProximos.length ?? 0;
              final dayFocus = DashboardDayFocus.resolve(
                riscoAlto: riscoAlto,
                alunosAtivos: alunosAtivos,
                checkinsHoje: checkinsHoje,
                agendaHoje: agendaHoje,
                receitaMes: receitaAtual,
                vencimentosPendentes: vencimentosCount,
                riskDominante: riskDominante,
              );
              final dayFocusCoversRetention =
                  dayFocus.headline == 'Cobrança e retenção hoje' ||
                  dayFocus.headline == 'Retomada urgente da base';

              final attentionRiskItems =
                  alunosEmRisco.take(riskDominante ? 2 : 4).toList();
              final attentionVencItems =
                  (_finData?.vencimentosProximos ?? const []).take(2).toList();
              final attentionItemCount =
                  attentionRiskItems.length + attentionVencItems.length;
              const commandCenterSubtitle =
                  'Próximas ações com maior impacto hoje.';

              void openAttentionReview() {
                if (attentionRiskItems.isNotEmpty) {
                  context.push('/alunos/${attentionRiskItems.first.id}');
                  return;
                }
                if (attentionVencItems.isNotEmpty) {
                  context.go('/financeiro');
                  return;
                }
                context.go('/alunos?filtro=risco');
              }

              final filaAcoes = commandAsync.maybeWhen(
                data: (cc) => cc.filaAcoes,
                orElse: () => const <FilaAcaoResumo>[],
              );
              final chatAsync = ref.watch(chatInboxProvider);
              final unreadCount = chatAsync.maybeWhen(
                data: (items) =>
                    items.fold<int>(0, (sum, item) => sum + item.naoLidas),
                orElse: () => 0,
              );
              final alunosRiscoCount = commandAsync.maybeWhen(
                data: (cc) => cc.alunosEmRisco.length,
                orElse: () => 0,
              );
              final cobrancasPendentes =
                  commandAsync.maybeWhen(
                    data: (cc) => cc.cobrancasPendentes.length,
                    orElse: () => _finData?.totalInadimplentes ?? 0,
                  );
              final dashboardNextActions = buildDashboardNextActions(
                filaAcoes: filaAcoes,
                unreadCount: unreadCount,
                alunosRisco: alunosRiscoCount,
                cobrancasPendentes: cobrancasPendentes,
                agendaHoje: agendaHoje,
                hideRiskSummary: alunosEmRisco.isNotEmpty,
                isCommandPreparing: commandAsync.isLoading,
              );
              final showStickyPrioritiesAction =
                  dashboardNextActions.length > 1 && _homeScrollOffset >= 80;
              final stickyCommandActionsLabel =
                  dashboardNextActions.length > 1 ? 'Ver prioridades' : null;

              void openCommandQuickActions() {
                if (dashboardNextActions.length < 2) return;
                showCommandActionsSheet(
                  context,
                  isDark: themeDark,
                  primary: primary,
                  actions: buildDashboardSheetActions(
                    curated: dashboardNextActions,
                    filaAcoes: filaAcoes,
                  ),
                );
              }

              final String? attentionCollapsedPreview;
              if (attentionRiskItems.isNotEmpty) {
                final first = attentionRiskItems.first;
                attentionCollapsedPreview =
                    '${first.nome} · ${attentionSignalLabel(first)}';
              } else if (attentionVencItems.isNotEmpty) {
                final first = attentionVencItems.first;
                attentionCollapsedPreview =
                    '${first.alunoNome} · R\$ ${first.valor.toStringAsFixed(0)} pendente';
              } else {
                attentionCollapsedPreview = null;
              }

              final link = BrandPalette.sectionLink(primary, dark: themeDark);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(dashboardHomeProvider);
                  ref.invalidate(alunosProvider);
                  ref.invalidate(historicoCheckinProvider);
                  ref.invalidate(aderenciaTop3Provider);
                  ref.invalidate(notificacoesProvider);
                  ref.invalidate(notificacoesNaoLidasProvider);
                  ref.invalidate(onboardingStatusProvider);
                  await _loadFinFromHome();
                  if (context.mounted) {
                    FeedbackHelper.showSuccess(
                      context,
                      'Painel atualizado',
                    );
                  }
                },
                child: CustomScrollView(
                  controller: _homeScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: TrialCountdownBanner()),
                    const SliverToBoxAdapter(child: PlanUsageBanner()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          4,
                          TokensStrip.s4,
                          0,
                        ),
                        child: SetupOnboardingWidget(),
                      ),
                    ),
                    if (!onboardingIncomplete)
                      SliverToBoxAdapter(
                        child: DashboardActivationCta(
                          alunosAtivos: alunosAtivos,
                          temTreinos: primeiroTreinoCriado || checkinsHoje > 0,
                          temFinanceiro: _finData != null &&
                              (_finData!.receitaMes > 0 ||
                                  _finData!.vencimentosProximos.isNotEmpty),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          4,
                          TokensStrip.s4,
                          TokensStrip.s3,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    dashboardGreeting(data.nomePersonal),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.35,
                                      height: 1.15,
                                      color:
                                          themeDark
                                              ? EagleTokens.darkInk
                                              : TokensStrip.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ShellThemeToggle(size: 36),
                                const SizedBox(width: 6),
                                const NotificacaoBadgeButton(size: 36),
                                const SizedBox(width: 6),
                                DashboardHeaderProfileAvatar(
                                  primary: primary,
                                  isDark: themeDark,
                                  photoUrl: data.logoUrl,
                                  initials: fxInitials(
                                    data.nomePersonal ?? 'F',
                                  ),
                                  onTap: () => context.push('/perfil'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DashboardDayFocusBanner(
                        focus: dayFocus,
                        isDark: themeDark,
                        primary: primary,
                      ),
                    ),

                    // CENTRAL DE COMANDO — protagonista do dia
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: DashboardCommandCenterStickyHeaderDelegate(
                        isDark: themeDark,
                        primary: primary,
                        subtitle: commandCenterSubtitle,
                        showPrioritiesAction: showStickyPrioritiesAction,
                        trailingActionLabel: stickyCommandActionsLabel,
                        onTrailingAction:
                            stickyCommandActionsLabel != null
                                ? openCommandQuickActions
                                : null,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: dashboardEntryMotion(
                        context: context,
                        fade: _commandFade,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            0,
                            TokensStrip.s4,
                            TokensStrip.s4,
                          ),
                          child: DashboardCommandCenterSection(
                            isDark: themeDark,
                            primary: primary,
                            finData: _finData,
                            hideRiskSummary: alunosEmRisco.isNotEmpty,
                            hideHeader: true,
                            contextualSubtitle: commandCenterSubtitle,
                          ),
                        ),
                      ),
                    ),

                    if (riscoAlto > 0 && !attentionVisible)
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/retencao'),
                            child: const Text('Ver saúde da base'),
                          ),
                        ),
                      ),

                    // PRECISA DE ATENÇÃO — colapsável quando muitos sinais
                    if (attentionVisible) ...[
                      SliverToBoxAdapter(
                        child: DashboardCollapsibleSection(
                          title: 'Precisa de atenção',
                          collapsedHint:
                              riskDominante
                                  ? '$riscoAlto de $alunosAtivos · toque em Revisar'
                                  : riscoAlto > 0
                                  ? '$riscoAlto no radar · toque em Revisar'
                                  : 'Cobranças pendentes · toque em Revisar',
                          collapsedActionLabel: 'Revisar',
                          onCollapsedAction: openAttentionReview,
                          collapsedPreview: attentionCollapsedPreview,
                          isDark: themeDark,
                          initiallyExpanded:
                              !dayFocusCoversRetention && riscoAlto <= 3,
                          resetToken: _attentionSectionResetToken,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push('/retencao'),
                                  child: const Text('Saúde da base'),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed:
                                      () => context.go('/alunos?filtro=risco'),
                                  child: Text(
                                    riscoAlto > 1
                                        ? 'Ver tudo · +${riscoAlto - 1}'
                                        : 'Ver tudo',
                                  ),
                                ),
                              ),
                              Semantics(
                                container: true,
                                explicitChildNodes: true,
                                label: dashboardAttentionCarouselSemantics(
                                  attentionItemCount,
                                ),
                                child: DashboardHorizontalScrollPeek(
                                  showPeek: attentionItemCount > 1,
                                  child: SizedBox(
                                    height: 184,
                                    child: ListView.separated(
                                      // ignore: deprecated_member_use
                                      cacheExtent: 280,
                                      key: const PageStorageKey(
                                        'personal-attention-rail',
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: TokensStrip.s4,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: attentionItemCount,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        if (index < attentionRiskItems.length) {
                                          final aluno = attentionRiskItems[index];
                                          return RepaintBoundary(
                                            child: DashboardAttentionCard(
                                            listIndex: index + 1,
                                            listTotal: attentionItemCount,
                                            nome: aluno.nome,
                                            objetivo: aluno.objetivo,
                                            titulo: attentionSignalLabel(aluno),
                                            subt: attentionSignalSub(aluno),
                                            acao: 'Revisar',
                                            isDark: themeDark,
                                            showStatusBadge:
                                                !riskDominante ||
                                                aluno.inadimplente ||
                                                aluno.statusFinanceiro ==
                                                    'INADIMPLENTE',
                                            statusAccent: EagleTokens.warn,
                                            onTap:
                                                () => context.push(
                                                  '/alunos/${aluno.id}',
                                                ),
                                          ),
                                          );
                                        }
                                        final v =
                                            attentionVencItems[index -
                                                attentionRiskItems.length];
                                        return RepaintBoundary(
                                          child: DashboardAttentionCard(
                                          listIndex: index + 1,
                                          listTotal: attentionItemCount,
                                          nome: v.alunoNome,
                                          titulo: 'Inadimplente',
                                          subt:
                                              'R\$ ${v.valor.toStringAsFixed(0)} pendente',
                                          acao: 'Cobrar',
                                          isDark: themeDark,
                                          onTap:
                                              () => context.go('/financeiro'),
                                        ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],

                    // PULSO DO DIA — operação antes de receita
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s2,
                          TokensStrip.s4,
                          TokensStrip.s4,
                        ),
                        child: DashboardDayPulseStrip(
                          fade: _kpiFade,
                          isDark: themeDark,
                          alunosAtivos: alunosAtivos,
                          checkinsHoje: checkinsHoje,
                          checkinsTrend: checkinsTrend,
                          riscoAlto: riscoAlto,
                          agendaHoje: agendaHoje,
                          hideRiscoChip: alunosEmRisco.isNotEmpty,
                          primary: primary,
                          onAtivos: () => context.go('/alunos?filtro=ativos'),
                          onCheckins: () => context.go('/checkin/historico'),
                          onAgenda: () => context.go('/agenda'),
                          onRisco:
                              riscoAlto > 0
                                  ? () => context.go('/alunos?filtro=risco')
                                  : () => context.go('/alunos'),
                          showEmptyTrendCta:
                              !checkinsTrend.any((v) => v > 0) &&
                              alunosAtivos > 0 &&
                              !dayFocusCoversRetention &&
                              !primeiroTreinoCriado &&
                              checkinsHoje == 0,
                          emptyTrendCtaLabel: 'Agendar primeiro treino',
                          onEmptyTrendCta: () => context.push('/treinos/novo'),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverToBoxAdapter(
                      child: DashboardCollapsibleSection(
                        title: 'Aderência da semana',
                        collapsedHint:
                            'Treinos parados e ranking · toque para expandir',
                        isDark: themeDark,
                        headerActionLabel: 'Relatório',
                        onHeaderAction:
                            () => context.push('/relatorios/global'),
                        child: DashboardAderenciaSemanaWidget(
                          isDark: themeDark,
                          retentionFocus: dayFocusCoversRetention,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    SliverToBoxAdapter(
                      child: DashboardCollapsibleSection(
                        title: 'Panorama financeiro',
                        collapsedHint:
                            receitaAtual > 0
                                ? 'R\$ ${receitaAtual.toInt()} recebido · toque para expandir'
                                : 'R\$ 0 recebido · meta do mês · toque para expandir',
                        isDark: themeDark,
                        initiallyExpanded:
                            !dayFocusCoversRetention && receitaAtual > 0,
                        child: dashboardEntryMotion(
                          context: context,
                          fade: _heroFade,
                          slideBegin: const Offset(0, 0.05),
                          child: DashboardFinancialHeroSection(
                            gradientCtrl: _gradientCtrl,
                            reduceMotion: reduceMotion,
                            themeDark: themeDark,
                            heroPrimary: heroPrimary,
                            heroDeep: heroDeep,
                            mes: mes,
                            receitaAtual: receitaAtual,
                            pendente: pendente,
                            progressRaw: progressRaw,
                            metaSuperada: metaSuperada,
                            loadingFin: _loadingFin,
                            counterAnim: _counterAnim,
                            finData: _finData,
                            receitaTrend: receitaTrend,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: DashboardCollapsibleToolsSection(
                        isDark: themeDark,
                        shortcutAspectRatio: shortcutAspectRatio,
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 88,
                      ),
                    ),
                  ],
                ),
              ),
                  if (showStickyPrioritiesAction &&
                      stickyCommandActionsLabel != null &&
                      _showsFloatingPrioritiesChip(_homeScrollOffset))
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 4,
                      right: TokensStrip.s4,
                      child: Semantics(
                        button: true,
                        label: stickyCommandActionsLabel,
                        child: Material(
                          elevation: 2,
                          shadowColor: Colors.black.withValues(
                            alpha: themeDark ? 0.35 : 0.12,
                          ),
                          color:
                              themeDark
                                  ? EagleTokens.darkCard
                                  : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            onTap: openCommandQuickActions,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                stickyCommandActionsLabel,
                                style: dashboardChipLabelStyle(link),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
    );
  }

}
