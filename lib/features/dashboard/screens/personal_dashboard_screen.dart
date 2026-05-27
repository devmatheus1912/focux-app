import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/aderencia_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../notificacoes/data/notificacoes_repository.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../subscription/widgets/plan_usage_banner.dart';
import '../../subscription/widgets/trial_countdown_banner.dart';
import '../../subscription/widgets/dashboard_activation_cta.dart';
import '../../pql/widgets/pql_progress_card.dart';

class PersonalDashboardScreen extends ConsumerStatefulWidget {
  const PersonalDashboardScreen({super.key});

  @override
  ConsumerState<PersonalDashboardScreen> createState() =>
      _PersonalDashboardScreenState();
}

String _dashboardGreeting(String? nome) {
  final hour = DateTime.now().hour;
  final prefix =
      hour < 12
          ? 'Bom dia'
          : hour < 18
          ? 'Boa tarde'
          : 'Boa noite';
  final first = nome?.split(' ').first.trim();
  if (first != null && first.isNotEmpty) {
    return '$prefix, ${fxTitleCaseName(first)}';
  }
  return prefix;
}

bool _isRiskEchoCopy(String text) {
  final lower = text.toLowerCase();
  return lower.contains('risco') ||
      lower.contains('abandono') ||
      lower.contains('aderência') ||
      lower.contains('aderencia');
}

String _attentionSignalLabel(Aluno aluno) {
  if (aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE') {
    return 'Inadimplente';
  }
  final dias = aluno.diasSemTreino;
  if (dias != null && dias >= 7) return '${dias}d s/ treino';
  if (aluno.emRisco) return 'Prioridade hoje';
  return 'Acompanhar';
}

String _attentionSignalSub(Aluno aluno) {
  if (aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE') {
    return 'Financeiro e aderência exigem contato';
  }
  final dias = aluno.diasSemTreino;
  if (dias != null && dias >= 14) {
    return 'Retomada urgente antes de perder ritmo';
  }
  if (dias != null && dias >= 7) {
    return 'Contato rápido para voltar ao treino';
  }
  return 'Acompanhar antes de perder ritmo';
}

TextStyle _dashboardSectionKickerStyle(
  BuildContext context, {
  required bool isDark,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  return AppTypography.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.35,
    color: BrandPalette.sectionLink(primary, dark: isDark),
  );
}

String _financeInadimplLabel(double width) =>
    width < 360 ? 'Inadimpl.' : 'Inadimplentes';

String _financePercentLabel(double progressRaw, {required bool exceeded}) {
  final pct = (progressRaw * 100).round();
  if (exceeded) {
    return '$pct% da meta · barra no teto';
  }
  return '$pct% da meta';
}

Color _pulseCheckinsAccent({
  required int checkinsHoje,
  required Color neutralAccent,
}) =>
    checkinsHoje > 0 ? EagleTokens.good : neutralAccent;

/// Fade na borda direita para indicar scroll horizontal.
class _HorizontalScrollPeek extends StatelessWidget {
  const _HorizontalScrollPeek({
    required this.child,
    required this.showPeek,
  });

  final Widget child;
  final bool showPeek;

  @override
  Widget build(BuildContext context) {
    if (!showPeek) return child;

    final base = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: 'Deslize horizontalmente para ver mais',
          child: child,
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    base.withValues(alpha: 0),
                    base.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonalDashboardScreenState
    extends ConsumerState<PersonalDashboardScreen>
    with TickerProviderStateMixin {
  FinanceiroDashboard? _finData;
  bool _loadingFin = true;

  late AnimationController _gradientCtrl;
  late AnimationController _counterCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _counterAnim;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _kpiFade;
  late Animation<double> _commandFade;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_heroFade);
    _kpiFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.48, 0.92, curve: Curves.easeOutCubic),
    );
    _commandFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.08, 0.58, curve: Curves.easeOutCubic),
    );
    _loadFin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _counterCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFin() async {
    if (mounted) {
      setState(() {
        _loadingFin = true;
      });
    }
    try {
      final data =
          await FinanceiroRepository(ref.read(apiClientProvider)).dashboard();
      if (mounted) {
        setState(() {
          _finData = data;
          _loadingFin = false;
        });
        _counterAnim = Tween<double>(
          begin: 0,
          end: _finData!.receitaMes,
        ).animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
        _counterCtrl.forward(from: 0);
      }
    } catch (e, st) {
      debugPrint('[Focux] Error loading financeiro dashboard: $e\n$st');
      if (mounted) {
        setState(() {
          _loadingFin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heroPrimary = BrandPalette.softened(primary, amount: 0.06);
    final heroDeep = BrandPalette.deep(heroPrimary);
    final dashboardAsync = ref.watch(dashboardProvider);
    final themeDark = Theme.of(context).brightness == Brightness.dark;
    final alunosAsync = ref.watch(alunosProvider);
    final historicoCheckinsAsync = ref.watch(historicoCheckinProvider);
    final chromeOnDark = themeDark;

    return Scaffold(
      backgroundColor: shellScaffoldColor,
      body: SafeArea(
        bottom: false,
        child: dashboardAsync.when(
          loading: () => _buildShimmerLoading(context, themeDark),
          error:
              (e, _) => _DashboardErrorState(
                chromeOnDark: chromeOnDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () {
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(commandCenterProvider);
                  ref.invalidate(alunosProvider);
                },
              ),
          data: (data) {
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
              final commandAsync = ref.watch(commandCenterProvider);
              final agendaHoje = commandAsync.maybeWhen(
                data: (cc) => cc.agendaHoje.length,
                orElse: () => 0,
              );
              final attentionVisible = alunosEmRisco.isNotEmpty ||
                  (_finData != null &&
                      _finData!.vencimentosProximos.isNotEmpty);
              final riskDominante =
                  alunosAtivos > 0 &&
                  riscoAlto >= math.max(2, (alunosAtivos * 0.5).ceil());

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(commandCenterProvider);
                  ref.invalidate(alunosProvider);
                  ref.invalidate(historicoCheckinProvider);
                  ref.invalidate(notificacoesProvider);
                  ref.invalidate(notificacoesNaoLidasProvider);
                  await _loadFin();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: TrialCountdownBanner()),
                    const SliverToBoxAdapter(child: PlanUsageBanner()),
                    const SliverToBoxAdapter(child: PqlProgressCard()),
                    SliverToBoxAdapter(
                      child: DashboardActivationCta(
                        alunosAtivos: alunosAtivos,
                        temTreinos: checkinsHoje > 0 || alunosAtivos == 0,
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
                                    _dashboardGreeting(data.nomePersonal),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    'Prioridades do dia',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          themeDark
                                              ? EagleTokens.darkInkMute
                                              : TokensStrip.textSecondary,
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
                                _HeaderProfileAvatar(
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

                    // CENTRAL DE COMANDO — protagonista do dia
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _commandFade,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(_commandFade),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              TokensStrip.s4,
                              0,
                              TokensStrip.s4,
                              TokensStrip.s4,
                            ),
                            child: _CommandCenterSection(
                              isDark: themeDark,
                              primary: primary,
                              finData: _finData,
                              hideRiskSummary: alunosEmRisco.isNotEmpty,
                              contextualSubtitle:
                                  alunosEmRisco.isNotEmpty
                                      ? 'Foco em cobrança, mensagens e agenda. Alunos em risco estão logo abaixo.'
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (riscoAlto > 0)
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/retencao'),
                            child: const Text('Ver saúde da base (churn)'),
                          ),
                        ),
                      ),

                    // PRECISA DE ATENÇÃO — rostos + CTA (só quando houver sinal)
                    if (attentionVisible) ...[
                      SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Precisa de atenção',
                          subtitle:
                              riskDominante
                                  ? '$riscoAlto de $alunosAtivos · retomada urgente'
                                  : riscoAlto > 0
                                  ? '$riscoAlto no radar hoje'
                                  : null,
                          action:
                              riscoAlto > 1
                                  ? 'Ver tudo · +${riscoAlto - 1}'
                                  : 'Ver tudo',
                          onAction: () => context.go('/alunos?filtro=risco'),
                          isDark: themeDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _HorizontalScrollPeek(
                          showPeek:
                              [
                                ...alunosEmRisco.take(riskDominante ? 2 : 4),
                                ...(_finData?.vencimentosProximos ?? const [])
                                    .take(2),
                              ].length >
                              1,
                          child: SizedBox(
                          height: 168,
                          child: ListView.separated(
                            key: const PageStorageKey(
                              'personal-attention-rail',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: TokensStrip.s4,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                [
                                  ...alunosEmRisco.take(riskDominante ? 2 : 4),
                                  ...(_finData?.vencimentosProximos ?? const [])
                                      .take(2),
                                ].length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final riskItems =
                                  alunosEmRisco
                                      .take(riskDominante ? 2 : 4)
                                      .toList();
                              if (index < riskItems.length) {
                                final aluno = riskItems[index];
                                return _AttentionCard(
                                  nome: aluno.nome,
                                  objetivo: aluno.objetivo,
                                  titulo: _attentionSignalLabel(aluno),
                                  subt: _attentionSignalSub(aluno),
                                  acao: 'Revisar',
                                  isDark: themeDark,
                                  showStatusBadge:
                                      !riskDominante ||
                                      aluno.inadimplente ||
                                      aluno.statusFinanceiro ==
                                          'INADIMPLENTE',
                                  statusAccent:
                                      aluno.inadimplente ||
                                              aluno.statusFinanceiro ==
                                                  'INADIMPLENTE'
                                          ? EagleTokens.warn
                                          : EagleTokens.warn,
                                  onTap:
                                      () => context.push('/alunos/${aluno.id}'),
                                );
                              }
                              final v =
                                  (_finData!.vencimentosProximos)[index -
                                      riskItems.length];
                              return _AttentionCard(
                                nome: v.alunoNome,
                                titulo: 'Inadimplente',
                                subt:
                                    'R\$ ${v.valor.toStringAsFixed(0)} pendente',
                                acao: 'Cobrar',
                                isDark: themeDark,
                                onTap: () => context.go('/financeiro'),
                              );
                            },
                          ),
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
                        child: _DayPulseStrip(
                          fade: _kpiFade,
                          isDark: themeDark,
                          alunosAtivos: alunosAtivos,
                          checkinsHoje: checkinsHoje,
                          riscoAlto: riscoAlto,
                          agendaHoje: agendaHoje,
                          hideRiscoChip: alunosEmRisco.isNotEmpty,
                          primary: primary,
                          onAtivos: () => context.go('/alunos?filtro=ativos'),
                          onCheckins: () => context.go('/agenda'),
                          onAgenda: () => context.go('/agenda'),
                          onRisco:
                              riscoAlto > 0
                                  ? () => context.go('/alunos?filtro=risco')
                                  : () => context.go('/alunos'),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: 'Aderência da semana',
                        action: 'Relatório',
                        onAction: () => context.push('/relatorios/global'),
                        isDark: themeDark,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TokensStrip.s4,
                        ),
                        child: _AderenciaSemanaWidget(isDark: themeDark),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    // PANORAMA FINANCEIRO — contexto, não protagonista
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s4,
                          TokensStrip.s4,
                          0,
                        ),
                        child: Text(
                          'Panorama financeiro',
                          style: _dashboardSectionKickerStyle(
                            context,
                            isDark: themeDark,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _heroFade,
                        child: SlideTransition(
                          position: _heroSlide,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AnimatedBuilder(
                              animation: _gradientCtrl,
                              builder: (ctx, _) {
                                final angle = _gradientCtrl.value * 2 * math.pi;
                                final begin = Alignment(
                                  -math.cos(angle),
                                  -math.sin(angle),
                                );
                                final end = Alignment(
                                  math.cos(angle),
                                  math.sin(angle),
                                );
                                return InkWell(
                                  onTap: () => context.go('/financeiro'),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        colors:
                                            themeDark
                                                ? const [
                                                  Color(0xFF128989),
                                                  Color(0xFF0A2E2E),
                                                ]
                                                : [heroPrimary, heroDeep],
                                        begin: begin,
                                        end: end,
                                      ),
                                      boxShadow: [
                                        ...TokensStrip.coloredDepthGlow(
                                          heroPrimary,
                                          strength: themeDark ? 0.28 : 0.34,
                                        ),
                                        BoxShadow(
                                          color: heroPrimary.withValues(
                                            alpha: themeDark ? 0.22 : 0.16,
                                          ),
                                          blurRadius: themeDark ? 32 : 26,
                                          offset: const Offset(0, 14),
                                          spreadRadius: themeDark ? -12 : -16,
                                        ),
                                      ],
                                    ),
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  16,
                                ),
                                child: CustomPaint(
                                  foregroundPainter: _HeroGridPainter(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Receita recebida · $mes',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        metaSuperada
                                            ? 'Meta superada · ${(progressRaw * 100).round()}% do objetivo.'
                                            : pendente > 0
                                            ? 'Recebido agora. Faltam R\$ ${pendente.toInt()} para a meta.'
                                            : 'Recebido agora. Meta do mês sob controle.',
                                        style: TextStyle(
                                          color:
                                              metaSuperada
                                                  ? Colors.white.withValues(
                                                    alpha: 0.88,
                                                  )
                                                  : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _loadingFin
                                              ? Shimmer.fromColors(
                                                baseColor: Colors.white
                                                    .withValues(alpha: 0.15),
                                                highlightColor: Colors.white
                                                    .withValues(alpha: 0.30),
                                                child: Container(
                                                  width: 160,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              : AnimatedBuilder(
                                                animation: _counterAnim,
                                                builder:
                                                    (ctx, _) => Text(
                                                      'R\$ ${_counterAnim.value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                                                      style:
                                                          AppTypography.mono(
                                                            color: Colors.white,
                                                            fontSize: 34,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: -0.5,
                                                            height: 1,
                                                          ),
                                                    ),
                                              ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                              bottom: 5,
                                            ),
                                            child: Text(
                                              'recebido',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.62,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            'Meta R\$ ${_finData?.previsaoReceita.toStringAsFixed(0) ?? '--'}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (metaSuperada) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.14,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      TokensStrip.rInput,
                                                    ),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.28),
                                                ),
                                              ),
                                              child: const Text(
                                                'SUPERADA',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.55,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _HeroProgressRail(
                                        progress: progressRaw.clamp(0.0, 1.0),
                                        exceeded: metaSuperada,
                                        glow: BrandPalette.accent(heroPrimary),
                                        percentLabel: _financePercentLabel(
                                          progressRaw,
                                          exceeded: metaSuperada,
                                        ),
                                        excessBeyondMeta:
                                            metaSuperada
                                                ? math.max(
                                                  0,
                                                  progressRaw - 1,
                                                )
                                                : 0,
                                      ),
                                      const SizedBox(height: TokensStrip.s3),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _HeroMiniStat(
                                            label: 'Pendente',
                                            value: 'R\$ ${pendente.toInt()}',
                                          ),
                                          Container(
                                            width: 1,
                                            height: 30,
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                          _HeroMiniStat(
                                            label: _financeInadimplLabel(
                                              MediaQuery.sizeOf(context).width,
                                            ),
                                            value:
                                                '${_finData?.totalInadimplentes ?? 0}',
                                            suffix: ' alunos',
                                          ),
                                          Container(
                                            width: 1,
                                            height: 30,
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                          _HeroMiniStat(
                                            label: 'Ticket médio',
                                            value:
                                                'R\$ ${_finData?.ticketMedio.toStringAsFixed(0) ?? '0'}',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: _CollapsibleToolsSection(
                        isDark: themeDark,
                        shortcutAspectRatio: shortcutAspectRatio,
                      ),
                    ),


                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          0,
                          TokensStrip.s4,
                          0,
                        ),
                        child: SetupOnboardingWidget(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 88,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context, bool themeDark) {
    final base = themeDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight = themeDark ? EagleTokens.darkCardHi : TokensStrip.borderDefault;

    Widget bone(double w, double h, {double radius = 12}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 6, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bone(170, 18, radius: 8),
                      const SizedBox(height: 4),
                      bone(110, 10, radius: 6),
                    ],
                  ),
                ),
                bone(36, 36, radius: 18),
                const SizedBox(width: 6),
                bone(40, 40, radius: 20),
                const SizedBox(width: 6),
                bone(36, 36, radius: 18),
              ],
            ),

            const SizedBox(height: 14),

            bone(140, 16),
            const SizedBox(height: 12),
            for (int i = 0; i < 2; i++) ...[
              Padding(
                padding: EdgeInsets.only(bottom: i < 1 ? 10 : 0),
                child: Row(
                  children: [
                    bone(40, 40, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bone(160, 13),
                          const SizedBox(height: 6),
                          bone(100, 10),
                        ],
                      ),
                    ),
                    bone(28, 28, radius: 8),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            bone(double.infinity, 200, radius: 28),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: bone(double.infinity, 52, radius: 12)),
                const SizedBox(width: 8),
                Expanded(child: bone(double.infinity, 52, radius: 12)),
                const SizedBox(width: 8),
                Expanded(child: bone(double.infinity, 52, radius: 12)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Aderência section ──
            bone(120, 16),
            const SizedBox(height: 14),
            for (int i = 0; i < 4; i++) ...[
              Padding(
                padding: EdgeInsets.only(bottom: i < 3 ? 8 : 0),
                child: Row(
                  children: [
                    bone(36, 36, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bone(140, 12),
                          const SizedBox(height: 5),
                          bone(80, 9),
                        ],
                      ),
                    ),
                    bone(40, 14, radius: 7),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderProfileAvatar extends StatelessWidget {
  const _HeaderProfileAvatar({
    required this.primary,
    required this.isDark,
    required this.initials,
    required this.onTap,
    this.photoUrl,
  });

  final Color primary;
  final bool isDark;
  final String initials;
  final VoidCallback onTap;
  final String? photoUrl;

  static const double _outer = 40;
  static const double _ring = 2;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final neon = BrandPalette.accent(primary);
    final avatarRadius = (_outer - _ring * 2 - _gap * 2) / 2;
    const glowPad = 5.0;

    return Semantics(
      button: true,
      label: 'Abrir perfil',
      child: SizedBox(
        width: _outer + glowPad * 2,
        height: _outer + glowPad * 2,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: _outer,
              height: _outer,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: neon.withValues(alpha: isDark ? 0.34 : 0.24),
                    blurRadius: isDark ? 12 : 10,
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              clipBehavior: Clip.none,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                splashColor: neon.withValues(alpha: 0.12),
                highlightColor: neon.withValues(alpha: 0.06),
                child: Container(
                  width: _outer,
                  height: _outer,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: neon.withValues(alpha: isDark ? 0.98 : 0.88),
                      width: _ring,
                    ),
                  ),
                  padding: const EdgeInsets.all(_gap),
                  child: ClipOval(
                    child:
                        photoUrl != null && photoUrl!.isNotEmpty
                            ? Image.network(
                              photoUrl!,
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => ColoredBox(
                                    color: primary,
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: avatarRadius * 0.72,
                                        ),
                                      ),
                                    ),
                                  ),
                            )
                            : ColoredBox(
                              color: primary,
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: avatarRadius * 0.72,
                                  ),
                                ),
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroProgressRail extends StatelessWidget {
  const _HeroProgressRail({
    required this.progress,
    required this.glow,
    this.exceeded = false,
    this.percentLabel,
    this.excessBeyondMeta = 0,
  });

  final double progress;
  final Color glow;
  final bool exceeded;
  final String? percentLabel;
  final double excessBeyondMeta;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final displayProgress = exceeded ? 1.0 : clamped;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (percentLabel != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              percentLabel!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        if (percentLabel != null) const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fillWidth = width * displayProgress;

            return SizedBox(
              height: exceeded ? 12 : 14,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: Colors.white.withValues(
                        alpha: exceeded ? 0.20 : 0.14,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: exceeded ? 0.30 : 0.20,
                        ),
                      ),
                    ),
                  ),
                  if (fillWidth > 2)
                    Positioned(
                      left: 0,
                      width: fillWidth,
                      height: exceeded ? 10 : 10,
                      top: exceeded ? 1 : 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors:
                                exceeded
                                    ? [
                                      Colors.white.withValues(alpha: 0.65),
                                      Colors.white.withValues(alpha: 0.95),
                                    ]
                                    : [
                                      Colors.white.withValues(alpha: 0.58),
                                      Colors.white.withValues(alpha: 0.86),
                                      glow.withValues(alpha: 0.88),
                                    ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: exceeded ? 0.48 : 0.36,
                              ),
                              blurRadius: exceeded ? 16 : 12,
                              spreadRadius: exceeded ? 1 : 0,
                            ),
                            BoxShadow(
                              color: glow.withValues(
                                alpha: exceeded ? 0.72 : 0.58,
                              ),
                              blurRadius: exceeded ? 22 : 18,
                              spreadRadius: exceeded ? 2 : 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (exceeded && excessBeyondMeta > 0)
                    Positioned(
                      right: -6,
                      top: exceeded ? -1 : 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Container(
                              width: 5,
                              height: exceeded ? 12 : 10,
                              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: Colors.white.withValues(
                                  alpha: 0.92 - (i * 0.22),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: glow.withValues(alpha: 0.55),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  const _HeroMiniStat({required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.5,
            letterSpacing: 0.08,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DayPulseStrip extends StatelessWidget {
  const _DayPulseStrip({
    required this.fade,
    required this.isDark,
    required this.alunosAtivos,
    required this.checkinsHoje,
    required this.riscoAlto,
    required this.agendaHoje,
    required this.hideRiscoChip,
    required this.primary,
    required this.onAtivos,
    required this.onCheckins,
    required this.onAgenda,
    required this.onRisco,
  });

  final Animation<double> fade;
  final bool isDark;
  final int alunosAtivos;
  final int checkinsHoje;
  final int riscoAlto;
  final int agendaHoje;
  final bool hideRiscoChip;
  final Color primary;
  final VoidCallback onAtivos;
  final VoidCallback onCheckins;
  final VoidCallback onAgenda;
  final VoidCallback onRisco;

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(fade);
    final riscoAccent =
        riscoAlto > 0 ? EagleTokens.warn : TokensStrip.badgeSuccess;
    final tight = MediaQuery.sizeOf(context).width < 400;
    final gap = tight ? 6.0 : TokensStrip.s2;
    final neutralAccent =
        isDark
            ? EagleTokens.darkInkMute.withValues(alpha: 0.72)
            : TokensStrip.textSecondary.withValues(alpha: 0.82);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pulso operacional',
              style: _dashboardSectionKickerStyle(context, isDark: isDark),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _PulseChip(
                    icon: 'users',
                    value: alunosAtivos.toString(),
                    label: 'Ativos',
                    accent: neutralAccent,
                    isDark: isDark,
                    compact: tight,
                    onTap: onAtivos,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _PulseChip(
                    icon: 'circle-check',
                    value: checkinsHoje.toString(),
                    label: tight ? 'Checks' : 'Check-ins',
                    accent: _pulseCheckinsAccent(
                      checkinsHoje: checkinsHoje,
                      neutralAccent: neutralAccent,
                    ),
                    isDark: isDark,
                    compact: tight,
                    onTap: onCheckins,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child:
                      hideRiscoChip
                          ? _PulseChip(
                            icon: 'calendar',
                            value: agendaHoje.toString(),
                            label: tight ? 'Agenda' : 'Agenda hoje',
                            accent: neutralAccent,
                            isDark: isDark,
                            compact: tight,
                            onTap: onAgenda,
                          )
                          : _PulseChip(
                            icon:
                                riscoAlto > 0
                                    ? 'alert-triangle'
                                    : 'circle-check',
                            value: riscoAlto.toString(),
                            label: 'Risco',
                            accent: riscoAccent,
                            isDark: isDark,
                            compact: tight,
                            onTap: onRisco,
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseChip extends StatelessWidget {
  const _PulseChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.compact,
    required this.onTap,
  });

  final String icon;
  final String value;
  final String label;
  final Color accent;
  final bool isDark;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final iconSize = compact ? 22.0 : 24.0;
    final iconGlyph = compact ? 11.0 : 12.0;
    final valueSize = compact ? 14.0 : 15.0;
    final labelSize = compact ? 9.5 : 10.0;
    final hPad = compact ? 7.0 : 9.0;

    return Semantics(
      button: true,
      label: '$value $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 9),
            decoration: fxStripCardDecoration(
              context,
              accent: accent,
              radius: TokensStrip.rCard,
              glowStrength: 0.14,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: isDark ? 0.18 : 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(TokensStrip.rInput),
                        ),
                        child: Center(
                          child: FxIcon(
                            name: icon,
                            size: iconGlyph,
                            color: accent,
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 5 : 6),
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 3),
                  Padding(
                    padding: EdgeInsets.only(left: iconSize + (compact ? 5 : 6)),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        height: 1.1,
                      ),
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final bool isDark;
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final actionColor = BrandPalette.sectionLink(primary, dark: isDark);
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, TokensStrip.s4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    fontSize: TokensStrip.fontH2,
                    fontWeight: TokensStrip.weightH2,
                    letterSpacing: TokensStrip.trackingH2,
                    height: 1.2,
                    color: heading,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTypography.inter(
                      fontSize: TokensStrip.fontBodySm,
                      fontWeight: FontWeight.w500,
                      color: mute,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null)
            Semantics(
              button: true,
              label: action,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onAction,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$action →',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: actionColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CollapsibleToolsSection extends StatefulWidget {
  const _CollapsibleToolsSection({
    required this.isDark,
    required this.shortcutAspectRatio,
  });

  final bool isDark;
  final double shortcutAspectRatio;

  @override
  State<_CollapsibleToolsSection> createState() =>
      _CollapsibleToolsSectionState();
}

class _CollapsibleToolsSectionState extends State<_CollapsibleToolsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: widget.isDark);
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final link = BrandPalette.sectionLink(primary, dark: widget.isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              expanded: _expanded,
              label:
                  _expanded
                      ? 'Recolher mais ferramentas'
                      : 'Expandir mais ferramentas, 6 atalhos',
              child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: fxStripCardDecoration(
                  context,
                  radius: TokensStrip.rCard,
                  glowStrength: 0.08,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mais ferramentas',
                            style: AppTypography.inter(
                              fontSize: TokensStrip.fontH2,
                              fontWeight: TokensStrip.weightH2,
                              letterSpacing: TokensStrip.trackingH2,
                              color: heading,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expanded
                                ? 'Acessos menos frequentes'
                                : '6 atalhos · toque para expandir',
                            style: AppTypography.inter(
                              fontSize: TokensStrip.fontBodySm,
                              fontWeight: FontWeight.w500,
                              color: mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: link,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 10,
                childAspectRatio: widget.shortcutAspectRatio,
                children: [
                  _ShortcutBtn(
                    icon: 'dumbbell',
                    label: 'Exercícios',
                    isDark: widget.isDark,
                    onTap: () => context.push('/exercicios'),
                  ),
                  _ShortcutBtn(
                    icon: 'article',
                    label: 'Feed',
                    isDark: widget.isDark,
                    onTap: () => context.push('/feed'),
                  ),
                  _ShortcutBtn(
                    icon: 'trend',
                    label: 'Leads',
                    isDark: widget.isDark,
                    onTap: () => context.push('/leads'),
                  ),
                  _ShortcutBtn(
                    icon: 'trend',
                    label: 'Indique',
                    isDark: widget.isDark,
                    onTap: () => context.push('/referral'),
                  ),
                  _ShortcutBtn(
                    icon: 'spark',
                    label: 'Ofertas',
                    isDark: widget.isDark,
                    onTap: () => context.push('/ofertas-upsell'),
                  ),
                  _ShortcutBtn(
                    icon: 'dumbbell',
                    label: 'Hábitos',
                    isDark: widget.isDark,
                    onTap: () => context.push('/habitos'),
                  ),
                  _ShortcutBtn(
                    icon: 'spark',
                    label: 'Pacotes',
                    isDark: widget.isDark,
                    onTap: () => context.push('/pacotes'),
                  ),
                  _ShortcutBtn(
                    icon: 'trend',
                    label: 'Lead Público',
                    isDark: widget.isDark,
                    onTap: () => context.push('/leads-publicos'),
                  ),
                  _ShortcutBtn(
                    icon: 'trend',
                    label: 'NDR / MRR',
                    isDark: widget.isDark,
                    onTap: () => context.push('/relatorio/business'),
                  ),
                  _ShortcutBtn(
                    icon: 'spark',
                    label: 'Qualidade',
                    isDark: widget.isDark,
                    onTap: () => context.push('/dashboard/qualidade'),
                  ),
                  _ShortcutBtn(
                    icon: 'bell',
                    label: 'Broadcasts',
                    isDark: widget.isDark,
                    onTap: () => context.push('/broadcasts'),
                  ),
                ],
              ),
            ),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final String nome, titulo, subt, acao;
  final String? objetivo;
  final bool isDark;
  final bool showStatusBadge;
  final Color? statusAccent;
  final VoidCallback? onTap;
  const _AttentionCard({
    required this.nome,
    required this.titulo,
    required this.subt,
    required this.acao,
    this.objetivo,
    required this.isDark,
    this.showStatusBadge = true,
    this.statusAccent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final accent = statusAccent ?? EagleTokens.warn;

    return Semantics(
      label: '$nome, $titulo. $subt. Toque para $acao',
      button: true,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        width: 240,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primary,
                  child: Text(
                    fxInitials(nome),
                    style: AppTypography.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fxTitleCaseName(nome),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      Text(
                        objetivo?.trim().isNotEmpty == true
                            ? objetivo!.trim()
                            : 'Objetivo não definido',
                        style: AppTypography.inter(fontSize: 11, color: mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (showStatusBadge) ...[
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      titulo.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              showStatusBadge ? subt : titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 12.2,
                color: ink,
                height: 1.25,
                fontWeight: showStatusBadge ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
            if (!showStatusBadge) ...[
              const SizedBox(height: 4),
              Text(
                subt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 11.5,
                  color: mute,
                  height: 1.25,
                ),
              ),
            ],
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: primarySoft,
                borderRadius: BorderRadius.circular(TokensStrip.rInput),
                border: Border.all(
                  color: primary.withValues(alpha: isDark ? 0.45 : 0.28),
                ),
                boxShadow: TokensStrip.coloredDepthGlow(
                  primary,
                  strength: 0.1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                acao,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BrandPalette.sectionAction(primary, dark: isDark),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ShortcutBtn extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _ShortcutBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryAccent = BrandPalette.accent(primary);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      label: label,
      button: true,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? primaryAccent : rowAccent).withValues(
                      alpha: isDark ? 0.20 : 0.12,
                    ),
                    (isDark ? primaryAccent : rowAccent).withValues(
                      alpha: isDark ? 0.08 : 0.04,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FxIcon(
                  name: icon,
                  size: 17,
                  color: isDark ? primaryAccent : rowAccent,
                  strokeWidth: 1.9,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FxIcon(
              name: 'chevron-right',
              size: 14,
              color: mute.withValues(alpha: 0.55),
              strokeWidth: 1.8,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// CENTRAL DE COMANDO
// ---------------------------------------------------------------------------

class _CommandCenterSection extends ConsumerWidget {
  final bool isDark;
  final Color primary;
  final FinanceiroDashboard? finData;
  final bool hideRiskSummary;
  final String? contextualSubtitle;

  const _CommandCenterSection({
    required this.isDark,
    required this.primary,
    required this.finData,
    this.hideRiskSummary = false,
    this.contextualSubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final actionColor = BrandPalette.sectionAction(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);

    // Chat inbox — count total unread messages
    final chatAsync = ref.watch(chatInboxProvider);
    final commandAsync = ref.watch(commandCenterProvider);
    final isCommandPreparing = chatAsync.isLoading || commandAsync.isLoading;
    final unreadCount = chatAsync.maybeWhen(
      data: (items) => items.fold<int>(0, (sum, i) => sum + i.naoLidas),
      orElse: () => 0,
    );
    final totalConversas = chatAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
    final chatSubtitle =
        unreadCount > 0
            ? '$unreadCount não lida${unreadCount == 1 ? '' : 's'}'
            : '$totalConversas conversa${totalConversas == 1 ? '' : 's'}';

    // Alunos — active student count (already in parent but we watch again for isolation)
    final alunosAsync = ref.watch(alunosProvider);
    final alunosAtivos = alunosAsync.maybeWhen(
      data: (alunos) => alunos.where((a) => a.status == 'ATIVO').length,
      orElse: () => 0,
    );

    // Agenda today — count from agendaHojeProvider (commandCenterProvider)
    final agendaHoje = commandAsync.maybeWhen(
      data: (cc) => cc.agendaHoje.length,
      orElse: () => 0,
    );
    final agendaSubtitle = agendaHoje > 0 ? '$agendaHoje hoje' : 'Sem agenda';

    // Financeiro — monthly revenue from already-loaded _finData
    final receitaMes = finData?.receitaMes ?? 0;
    final finSubtitle =
        receitaMes > 0
            ? 'R\$ ${receitaMes.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}'
            : 'Ver finanças';

    final alunosRisco = commandAsync.maybeWhen(
      data: (cc) => cc.alunosEmRisco.length,
      orElse: () => 0,
    );
    final filaAcoes = commandAsync.maybeWhen(
      data: (cc) => cc.filaAcoes,
      orElse: () => const <FilaAcaoResumo>[],
    );
    final copilotAcoes =
        filaAcoes.where((a) => a.tipo == 'IA_COPILOTO').toList();
    final cobrancasPendentes = commandAsync.maybeWhen(
      data: (cc) => cc.cobrancasPendentes.length,
      orElse: () => finData?.totalInadimplentes ?? 0,
    );
    final filaNaoCopilot =
        filaAcoes.where((a) => a.tipo != 'IA_COPILOTO').toList();
    final queueAction =
        filaNaoCopilot.isEmpty
            ? null
            : (hideRiskSummary &&
                    _isRiskEchoCopy(
                      '${filaNaoCopilot.first.titulo} ${filaNaoCopilot.first.descricao}',
                    )
                ? null
                : _CommandActionItem(
                  icon: 'zap',
                  title: 'Executar próxima ação',
                  subtitle: filaNaoCopilot.first.descricao,
                  route:
                      filaNaoCopilot.first.acaoUrl.startsWith('/')
                          ? filaNaoCopilot.first.acaoUrl
                          : '/dashboard/personal',
                  tone: _CommandActionTone.primary,
                ));
    final nextActions = <_CommandActionItem>[
      if (copilotAcoes.isNotEmpty)
        _CommandActionItem(
          icon: 'zap',
          title:
              copilotAcoes.first.titulo.isNotEmpty
                  ? copilotAcoes.first.titulo
                  : 'Revisar tarefa IA',
          subtitle: copilotAcoes.first.descricao,
          route: '/dashboard/command-center/copiloto',
          tone: _CommandActionTone.primary,
        ),
      if (unreadCount > 0)
        _CommandActionItem(
          icon: 'message-circle',
          title: 'Responder mensagens',
          subtitle:
              '$unreadCount conversa${unreadCount == 1 ? '' : 's'} aguardando',
          route: '/chat/inbox',
          tone: _CommandActionTone.hot,
        ),
      if (alunosRisco > 0 && !hideRiskSummary)
        _CommandActionItem(
          icon: 'alert-triangle',
          title: 'Contato hoje',
          subtitle:
              '$alunosRisco no radar · risco, inadimplência ou pausa no treino',
          route: '/alunos?filtro=contato',
          tone: _CommandActionTone.hot,
        ),
      if (cobrancasPendentes > 0)
        _CommandActionItem(
          icon: 'dollar-sign',
          title: 'Cobrar pendências',
          subtitle:
              '$cobrancasPendentes mensalidade${cobrancasPendentes == 1 ? '' : 's'} no radar',
          route: '/financeiro',
          tone: _CommandActionTone.money,
        ),
      if (queueAction != null) queueAction,
      if (agendaHoje > 0)
        _CommandActionItem(
          icon: 'calendar',
          title: 'Preparar agenda',
          subtitle: '$agendaHoje compromisso${agendaHoje == 1 ? '' : 's'} hoje',
          route: '/agenda',
          tone: _CommandActionTone.primary,
        ),
    ];
    if (nextActions.isEmpty && !isCommandPreparing) {
      nextActions.add(
        _CommandActionItem(
          icon: 'plus',
          title: 'Criar próxima oportunidade',
          subtitle: 'Cadastre aluno, treino ou lead antes do pico do dia',
          route: '/alunos/novo',
          tone: _CommandActionTone.primary,
        ),
      );
    }

    Widget card({
      required double width,
      required String icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: fxStripCardDecoration(
                context,
                accent: primary,
                radius: TokensStrip.rCard,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primarySoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: FxIcon(name: icon, size: 17, color: rowAccent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 11.2, color: mute),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Central de Comando',
                    style: AppTypography.inter(
                      fontSize: TokensStrip.fontH2,
                      fontWeight: TokensStrip.weightH2,
                      letterSpacing: TokensStrip.trackingH2,
                      height: 1.2,
                      color: heading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contextualSubtitle ??
                        'A melhor próxima ação para proteger receita e aderência.',
                    style: AppTypography.inter(
                      fontSize: TokensStrip.fontBodySm,
                      fontWeight: FontWeight.w400,
                      height: TokensStrip.leadingBody,
                      color: mute,
                    ),
                  ),
                ],
              ),
            ),
            if (nextActions.length > 1)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      isCommandPreparing
                          ? null
                          : () => _showCommandActionsSheet(
                            context,
                            isDark: isDark,
                            primary: primary,
                            actions: nextActions,
                          ),
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCommandPreparing
                              ? 'lendo sinais'
                              : 'Ver ${nextActions.length}',
                          style: TextStyle(
                            color: actionColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!isCommandPreparing) ...[
                          const SizedBox(width: 4),
                          FxIcon(
                            name: 'chevron-right',
                            size: 13,
                            color: actionColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _CommandActionPanel(
          isDark: isDark,
          primary: primary,
          loading: isCommandPreparing,
          actions: nextActions.take(2).toList(growable: false),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final moduleWidth = (constraints.maxWidth * 0.46).clamp(150.0, 188.0);
            return _HorizontalScrollPeek(
              showPeek: true,
              child: SizedBox(
              height: 82,
              child: ListView(
                key: const PageStorageKey('personal-command-modules'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  card(
                    width: moduleWidth,
                    icon: 'zap',
                    title: 'Copiloto',
                    subtitle:
                        copilotAcoes.isEmpty
                            ? 'Sem tarefas'
                            : '${copilotAcoes.length} aberta${copilotAcoes.length == 1 ? '' : 's'}',
                    onTap:
                        () => context.push('/dashboard/command-center/copiloto'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'message-circle',
                    title: 'Mensagens',
                    subtitle: chatSubtitle,
                    onTap: () => context.go('/chat/inbox'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'users',
                    title: 'Alunos',
                    subtitle: '$alunosAtivos ativos',
                    onTap: () => context.go('/alunos'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'calendar',
                    title: 'Agenda',
                    subtitle: agendaSubtitle,
                    onTap: () => context.go('/agenda'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'dollar-sign',
                    title: 'Financeiro',
                    subtitle: finSubtitle,
                    onTap: () => context.go('/financeiro'),
                  ),
                ],
              ),
            ),
            );
          },
        ),
      ],
    );
  }
}

void _showCommandActionsSheet(
  BuildContext context, {
  required bool isDark,
  required Color primary,
  required List<_CommandActionItem> actions,
}) {
  final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
  final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.56 : 0.24),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          math.max(12, media.viewPadding.bottom + 10),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxStripCardDecoration(
            sheetContext,
            radius: 28,
            glowStrength: isDark ? 0.28 : 0.48,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: line.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: FxIcon(name: 'route', size: 18, color: primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todas as prioridades',
                          style: TokensStrip.h2(
                            color: primary,
                            fontFamily:
                                Theme.of(sheetContext)
                                    .textTheme
                                    .bodyLarge
                                    ?.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ordenadas pelo impacto de hoje.',
                          style: TokensStrip.bodyMuted(
                            color: mute,
                            fontFamily:
                                Theme.of(sheetContext)
                                    .textTheme
                                    .bodyLarge
                                    ?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: 18, color: mute),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: actions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = actions[index];
                    return _CommandActionTile(
                      item: item,
                      isDark: isDark,
                      primary: primary,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        context.go(item.route);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _CommandActionTone { primary, hot, money }

Color _commandToneAccent(_CommandActionTone tone, Color primary) {
  return switch (tone) {
    _CommandActionTone.hot => Color.lerp(EagleTokens.warn, primary, 0.34)!,
    _CommandActionTone.money => const Color(0xFF0E9F6E),
    _CommandActionTone.primary => primary,
  };
}

class _CommandActionItem {
  final String icon;
  final String title;
  final String subtitle;
  final String route;
  final _CommandActionTone tone;

  const _CommandActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.tone,
  });
}

class _CommandActionPanel extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool loading;
  final List<_CommandActionItem> actions;

  const _CommandActionPanel({
    required this.isDark,
    required this.primary,
    required this.loading,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FxIcon(name: 'route', size: 17, color: rowAccent),
            const SizedBox(width: 8),
            Text(
              'Próximas ações',
              style: TokensStrip.h2(
                color: heading,
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
              ).copyWith(fontSize: 15),
            ),
            const Spacer(),
            Text(
              'Impacto hoje',
              style: TextStyle(
                color: BrandPalette.sectionLink(primary, dark: isDark),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(
          color:
              isDark
                  ? EagleTokens.glassBorder
                  : TokensStrip.borderDefault.withValues(alpha: 0.85),
          height: 1,
        ),
        const SizedBox(height: 12),
        if (loading)
          _CommandLoadingTile(isDark: isDark, primary: primary)
        else if (actions.isEmpty)
          _CommandLoadingTile(
            isDark: isDark,
            primary: primary,
            title: 'Operação sob controle',
            subtitle: 'Nenhuma ação crítica para agora.',
          )
        else
          for (var index = 0; index < actions.length; index++) ...[
            _CommandActionTile(
              item: actions[index],
              isDark: isDark,
              primary: primary,
            ),
            if (index < actions.length - 1) ...[
              const SizedBox(height: 10),
              Divider(
                color:
                    isDark
                        ? EagleTokens.glassBorder.withValues(alpha: 0.65)
                        : TokensStrip.borderDefault.withValues(alpha: 0.75),
                height: 1,
              ),
              const SizedBox(height: 10),
            ],
          ],
      ],
    );
  }
}

class _CommandLoadingTile extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final String title;
  final String subtitle;

  const _CommandLoadingTile({
    required this.isDark,
    required this.primary,
    this.title = 'Preparando prioridades',
    this.subtitle = 'Lendo mensagens, risco, agenda e financeiro.',
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final chrome = ShellChrome.forDark(isDark);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: chrome.panel(radius: TokensStrip.rCard, accent: primary),
      child: Row(
        children: [
          Shimmer.fromColors(
            baseColor: primary.withValues(alpha: isDark ? 0.18 : 0.10),
            highlightColor: primary.withValues(alpha: isDark ? 0.32 : 0.18),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: mute, fontSize: 11.6, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandActionTile extends StatelessWidget {
  final _CommandActionItem item;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;

  const _CommandActionTile({
    required this.item,
    required this.isDark,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final accent = _commandToneAccent(item.tone, primary);
    return Semantics(
      label: '${item.title}. ${item.subtitle}',
      button: true,
      child: InkWell(
      onTap: onTap ?? () => context.go(item.route),
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: fxStripCardDecoration(
            context,
            accent: accent,
            radius: TokensStrip.rCard,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.24 : 0.14),
                  borderRadius: BorderRadius.circular(TokensStrip.rInput),
                ),
                child: Center(
                  child: FxIcon(name: item.icon, color: accent, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.6,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FxIcon(name: 'chevron-right', color: mute, size: 20),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AderenciaSemanaWidget extends StatelessWidget {
  final bool isDark;
  const _AderenciaSemanaWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(aderenciaTop3Provider);
        return async.when(
          loading:
              () => Container(
                height: 184,
                padding: const EdgeInsets.all(14),
              decoration: fxStripCardDecoration(context, radius: TokensStrip.rCard),
                child: Column(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Shimmer.fromColors(
                        baseColor: primary.withValues(alpha: 0.08),
                        highlightColor: primary.withValues(alpha: 0.18),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 54,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
          error:
              (e, _) => Container(
                padding: const EdgeInsets.all(TokensStrip.s4),
              decoration: fxStripCardDecoration(context, radius: TokensStrip.rCard),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: EagleTokens.bad.withValues(
                          alpha: isDark ? 0.18 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: EagleTokens.bad,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Falha ao carregar aderência',
                            style: TextStyle(
                              color: ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verifique sua conexão e puxe para atualizar.',
                            style: TextStyle(
                              color: mute,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          data: (items) {
            if (items.isEmpty) {
              return _AderenciaSemanaEmptyCard(
                isDark: isDark,
                primary: primary,
                mute: mute,
                title: 'Sem check-ins nesta semana',
                body:
                    'Quando alunos treinarem, a aderência aparece aqui com ranking automático.',
                primaryAction: 'Abrir agenda',
                onPrimary: () => context.go('/agenda'),
              );
            }

            final semanaParada = items.every((a) => a.totalCheckinsSemana == 0);
            if (semanaParada) {
              return _AderenciaSemanaEmptyCard(
                isDark: isDark,
                primary: primary,
                mute: mute,
                title: 'Semana ainda parada',
                body:
                    'Nenhum check-in registrado. Acione sua base antes do fim da semana.',
                primaryAction: 'Ver agenda',
                secondaryAction: 'Plano retomada',
                onPrimary: () => context.go('/agenda'),
                onSecondary: () => context.push('/dashboard/qualidade'),
              );
            }

            return Container(
              decoration: fxStripCardDecoration(
                context,
                accent: primary,
                radius: TokensStrip.rCard,
              ),
              child: Column(
                children: List.generate(items.length, (index) {
                  final a = items[index];
                  return InkWell(
                    onTap: () => context.push('/alunos/${a.alunoId}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border:
                            index < items.length - 1
                                ? Border(
                                  bottom: BorderSide(
                                    color:
                                        isDark
                                            ? EagleTokens.darkLine
                                            : TokensStrip.borderDefault,
                                    width: 0.5,
                                  ),
                                )
                                : null,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: primarySoft,
                            child: Text(
                              fxInitials(a.nome),
                              style: TextStyle(
                                color: rowAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fxTitleCaseName(a.nome),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${a.objetivo ?? 'Objetivo'} · ${a.totalCheckinsSemana} check-ins',
                                  style: TextStyle(fontSize: 12, color: mute),
                                ),
                              ],
                            ),
                          ),
                          FxSparkline(
                            data: a.sparkline,
                            width: 56,
                            height: 22,
                            color: rowAccent,
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${a.aderenciaPercent}%',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

class _AderenciaSemanaEmptyCard extends StatelessWidget {
  const _AderenciaSemanaEmptyCard({
    required this.isDark,
    required this.primary,
    required this.mute,
    required this.title,
    required this.body,
    required this.primaryAction,
    required this.onPrimary,
    this.secondaryAction,
    this.onSecondary,
  });

  final bool isDark;
  final Color primary;
  final Color mute;
  final String title;
  final String body;
  final String primaryAction;
  final VoidCallback onPrimary;
  final String? secondaryAction;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxStripCardDecoration(
        context,
        accent: primary,
        radius: TokensStrip.rCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: FxIcon(
                    name: 'calendar',
                    size: 18,
                    color: BrandPalette.sectionAccent(primary, dark: isDark),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(color: mute, height: 1.35, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 340;
              final primaryBtn = SizedBox(
                width: stacked ? double.infinity : null,
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TokensStrip.rButton),
                    ),
                  ),
                  child: Text(primaryAction),
                ),
              );
              final secondaryBtn =
                  secondaryAction != null && onSecondary != null
                      ? SizedBox(
                        width: stacked ? double.infinity : null,
                        child: OutlinedButton(
                          onPressed: onSecondary,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                TokensStrip.rButton,
                              ),
                            ),
                          ),
                          child: Text(
                            secondaryAction!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5, height: 1.1),
                          ),
                        ),
                      )
                      : null;

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primaryBtn,
                    if (secondaryBtn != null) ...[
                      const SizedBox(height: 8),
                      secondaryBtn,
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: primaryBtn),
                  if (secondaryBtn != null) ...[
                    const SizedBox(width: 8),
                    Expanded(child: secondaryBtn),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Error State — replaces raw Text(friendlyError)
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardErrorState extends StatelessWidget {
  final bool chromeOnDark;
  final Color primary;
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorState({
    required this.chromeOnDark,
    required this.primary,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ink = chromeOnDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = chromeOnDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(alpha: chromeOnDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: EagleTokens.bad,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Algo saiu do ar',
              style: AppTypography.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
