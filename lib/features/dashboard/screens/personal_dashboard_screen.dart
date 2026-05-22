import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/cockpit_theme.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_logo.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_sparkline.dart';
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

class PersonalDashboardScreen extends ConsumerStatefulWidget {
  const PersonalDashboardScreen({super.key});

  @override
  ConsumerState<PersonalDashboardScreen> createState() =>
      _PersonalDashboardScreenState();
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
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_heroFade);
    _kpiFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.22, 0.82, curve: Curves.easeOutCubic),
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
    final dashboardAsync = ref.watch(dashboardProvider);
    final themeDark = Theme.of(context).brightness == Brightness.dark;
    final alunosAsync = ref.watch(alunosProvider);
    final historicoCheckinsAsync = ref.watch(historicoCheckinProvider);
    final notificacoesNaoLidas =
        ref.watch(notificacoesNaoLidasProvider).valueOrNull ?? 0;
    final chromeOnDark = themeDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FxLogo(
                                    iconSize: 34,
                                    showLabel: true,
                                    horizontal: true,
                                    light: chromeOnDark,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Hoje · Bom dia, ${data.nomePersonal?.split(' ').first ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          themeDark
                                              ? EagleTokens.darkInk
                                              : EagleTokens.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ShellThemeToggle(size: 36),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap:
                                      () => context.push(
                                        '/notificacoes',
                                      ), // Rota de notificações
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: ShellChrome.forDark(
                                      themeDark,
                                    ).headerAction(radius: 18),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        FxIcon(
                                          name: 'bell',
                                          size: 20,
                                          color:
                                              themeDark
                                                  ? EagleTokens.darkInk
                                                  : EagleTokens.ink,
                                          strokeWidth: 1.9,
                                        ),
                                        if (notificacoesNaoLidas > 0)
                                          Positioned(
                                            top: 8,
                                            right: 9,
                                            child: Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      themeDark
                                                          ? EagleTokens.darkCard
                                                          : EagleTokens.card,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap:
                                      () => context.push(
                                        '/perfil',
                                      ), // Rota de perfil do personal
                                  borderRadius: BorderRadius.circular(18),
                                  child:
                                      data.logoUrl != null &&
                                              data.logoUrl!.isNotEmpty
                                          ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              data.logoUrl!,
                                            ),
                                            radius: 18,
                                          )
                                          : CircleAvatar(
                                            radius: 18,
                                            backgroundColor: primary,
                                            child: Text(
                                              fxInitials(
                                                data.nomePersonal ?? 'F',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // HERO CARD
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
                                  borderRadius: BorderRadius.circular(28),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: LinearGradient(
                                        colors:
                                            themeDark
                                                ? const [
                                                  Color(0xFF159A9A),
                                                  Color(0xFF0A2E2E),
                                                ]
                                                : [
                                                  primary,
                                                  BrandPalette.deep(primary),
                                                ],
                                        begin: begin,
                                        end: end,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withValues(alpha: 0.32),
                                          blurRadius: 40,
                                          offset: const Offset(0, 20),
                                          spreadRadius: -20,
                                        ),
                                      ],
                                    ),
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  22,
                                  22,
                                  20,
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
                                        pendente > 0
                                            ? 'Recebido agora. Faltam R\$ ${pendente.toInt()} para a meta.'
                                            : 'Recebido agora. Meta do mês sob controle.',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          _loadingFin
                                              ? Shimmer.fromColors(
                                                baseColor: Colors.white
                                                    .withValues(alpha: 0.15),
                                                highlightColor: Colors.white
                                                    .withValues(alpha: 0.30),
                                                child: Container(
                                                  width: 180,
                                                  height: 42,
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
                                                          GoogleFonts.jetBrainsMono(
                                                            color: Colors.white,
                                                            fontSize: 42,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: -0.5,
                                                            height: 1,
                                                          ),
                                                    ),
                                              ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'recebido',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Meta R\$ ${_finData?.previsaoReceita.toStringAsFixed(0) ?? '--'}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor:
                                              (_finData == null ||
                                                      (_finData!
                                                              .previsaoReceita) ==
                                                          0)
                                                  ? 0.0
                                                  : (_finData!.receitaMes /
                                                          _finData!
                                                              .previsaoReceita)
                                                      .clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _HeroMiniStat(
                                            label: 'PENDENTE',
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
                                            label: 'INADIMPL.',
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
                                            label: 'TICKET',
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

                    // PULSO DO DIA — asymmetric KPI rail
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                        child: _KpiAsymmetricGrid(
                          fade: _kpiFade,
                          isDark: themeDark,
                          alunosAtivos: alunosAtivos,
                          checkinsHoje: checkinsHoje,
                          riscoAlto: riscoAlto,
                          primary: primary,
                          onAtivos: () => context.go('/alunos'),
                          onCheckins: () => context.push('/relatorios/global'),
                          onRisco: () => context.push('/dashboard/qualidade'),
                        ),
                      ),
                    ),

                    // CENTRAL DE COMANDO
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _CommandCenterSection(
                          isDark: themeDark,
                          primary: primary,
                          finData: _finData,
                        ),
                      ),
                    ),

                    // ONBOARDING WIDGET (Atualizado visualmente dentro dele se necessário, aqui chamamos)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SetupOnboardingWidget(),
                      ),
                    ),

                    // SECTION: PRECISA DE ATENÇÃO
                    if (alunosEmRisco.isNotEmpty ||
                        (_finData != null &&
                            _finData!.vencimentosProximos.isNotEmpty)) ...[
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Precisa de atenção',
                          action:
                              riscoAlto > 1
                                  ? 'Ver tudo · +${riscoAlto - 1}'
                                  : 'Ver tudo',
                          onAction: () => context.go('/alunos?filtro=risco'),
                          isDark: themeDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 168,
                          child: ListView.separated(
                            key: const PageStorageKey(
                              'personal-attention-rail',
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                [
                                  ...alunosEmRisco.take(4),
                                  ...(_finData?.vencimentosProximos ?? const [])
                                      .take(2),
                                ].length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final riskItems = alunosEmRisco.take(4).toList();
                              if (index < riskItems.length) {
                                final aluno = riskItems[index];
                                return _AttentionCard(
                                  nome: aluno.nome,
                                  objetivo: aluno.objetivo,
                                  titulo:
                                      aluno.inadimplente
                                          ? 'Inadimplente'
                                          : 'Risco de aderência',
                                  subt:
                                      aluno.inadimplente
                                          ? 'Financeiro e aderência exigem contato'
                                          : 'Acompanhar antes de perder ritmo',
                                  acao: 'Revisar',
                                  isDark: themeDark,
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
                    ],

                    // SEUS ALUNOS (ADERÊNCIA DA SEMANA)
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _AderenciaSemanaWidget(isDark: themeDark),
                      ),
                    ),

                    // ATALHOS — 6 quick action shortcuts (design spec)
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: 'Mais ferramentas',
                        isDark: themeDark,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          MediaQuery.of(context).padding.bottom + 90,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ToolGroupLabel(
                              label: 'Acessos menos frequentes',
                              isDark: themeDark,
                            ),
                            const SizedBox(height: 8),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 9,
                              crossAxisSpacing: 10,
                              childAspectRatio: shortcutAspectRatio,
                              children: [
                                _ShortcutBtn(
                                  icon: 'dumbbell',
                                  label: 'Exercícios',
                                  isDark: themeDark,
                                  onTap: () => context.push('/exercicios'),
                                ),
                                _ShortcutBtn(
                                  icon: 'article',
                                  label: 'Feed',
                                  isDark: themeDark,
                                  onTap: () => context.push('/feed'),
                                ),
                                _ShortcutBtn(
                                  icon: 'trend',
                                  label: 'Leads',
                                  isDark: themeDark,
                                  onTap: () => context.push('/leads'),
                                ),
                                _ShortcutBtn(
                                  icon: 'spark',
                                  label: 'Qualidade',
                                  isDark: themeDark,
                                  onTap:
                                      () =>
                                          context.push('/dashboard/qualidade'),
                                ),
                                _ShortcutBtn(
                                  icon: 'bell',
                                  label: 'Broadcasts',
                                  isDark: themeDark,
                                  onTap: () => context.push('/broadcasts'),
                                ),
                                _ShortcutBtn(
                                  icon: 'chat',
                                  label: 'Suporte',
                                  isDark: themeDark,
                                  onTap: () => context.push('/suporte'),
                                ),
                              ],
                            ),
                          ],
                        ),
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
    final base = themeDark ? EagleTokens.darkCard : EagleTokens.line;
    final highlight = themeDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft;

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header bar (logo + greeting + icons) ──
            Row(
              children: [
                bone(28, 28, radius: 8),
                const SizedBox(width: 10),
                bone(100, 14),
                const Spacer(),
                bone(36, 36, radius: 18),
                const SizedBox(width: 8),
                bone(36, 36, radius: 18),
                const SizedBox(width: 8),
                bone(36, 36, radius: 18),
              ],
            ),
            const SizedBox(height: 6),
            bone(180, 11),

            const SizedBox(height: 18),

            // ── Hero revenue card ──
            bone(double.infinity, 220, radius: 28),

            const SizedBox(height: 18),

            // ── 3 Stat tiles (Ativos, Check-ins, Risco) ──
            Row(
              children: [
                Expanded(child: bone(double.infinity, 92, radius: 20)),
                const SizedBox(width: 9),
                Expanded(child: bone(double.infinity, 92, radius: 20)),
                const SizedBox(width: 9),
                Expanded(child: bone(double.infinity, 92, radius: 20)),
              ],
            ),

            const SizedBox(height: 28),

            // ── Section title ──
            bone(140, 16),

            const SizedBox(height: 14),

            // ── Command center items ──
            for (int i = 0; i < 3; i++) ...[
              Padding(
                padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
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

            const SizedBox(height: 28),

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

class _KpiAsymmetricGrid extends StatelessWidget {
  const _KpiAsymmetricGrid({
    required this.fade,
    required this.isDark,
    required this.alunosAtivos,
    required this.checkinsHoje,
    required this.riscoAlto,
    required this.primary,
    required this.onAtivos,
    required this.onCheckins,
    required this.onRisco,
  });

  final Animation<double> fade;
  final bool isDark;
  final int alunosAtivos;
  final int checkinsHoje;
  final int riscoAlto;
  final Color primary;
  final VoidCallback onAtivos;
  final VoidCallback onCheckins;
  final VoidCallback onRisco;

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(fade);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: SizedBox(
          height: 196,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _QuickTile(
                  icon: 'users',
                  label: 'Ativos',
                  value: alunosAtivos.toString(),
                  accent: primary,
                  isDark: isDark,
                  tall: true,
                  onTap: onAtivos,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        icon: 'circle-check',
                        label: 'Check-ins',
                        value: checkinsHoje.toString(),
                        accent: EagleTokens.good,
                        isDark: isDark,
                        compact: true,
                        onTap: onCheckins,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _QuickTile(
                        icon: 'alert-triangle',
                        label: 'Risco',
                        value: riscoAlto.toString(),
                        accent: EagleTokens.warn,
                        isDark: isDark,
                        compact: true,
                        onTap: onRisco,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String icon;
  final String label, value;
  final Color accent;
  final bool isDark;
  final bool tall;
  final bool compact;
  final VoidCallback? onTap;
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.isDark,
    this.tall = false,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final numVal = int.tryParse(value) ?? 0;
    final valueSize = tall ? 28.0 : (compact ? 17.0 : 21.0);
    final labelSize = compact ? 10.0 : 11.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: tall || compact ? null : 92,
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 11,
            compact ? 9 : 11,
            compact ? 10 : 11,
            compact ? 8 : 10,
          ),
          decoration: chrome.accentPanel(accent: accent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 24 : 28,
                    height: compact ? 24 : 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(compact ? 10 : 12),
                    ),
                    child: Center(
                      child: FxIcon(
                        name: icon,
                        size: compact ? 12 : 14,
                        color: accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 5 : 6,
                      vertical: compact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          numVal > 0
                              ? accent.withValues(alpha: isDark ? 0.12 : 0.07)
                              : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      numVal > 0 ? 'ativo' : '—',
                      style: TextStyle(
                        fontSize: compact ? 8 : 9,
                        fontWeight: FontWeight.w800,
                        color: numVal > 0 ? accent : mute,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (tall) const Spacer(flex: 2) else const Spacer(),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w700,
                  color: ink,
                  height: 1,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: compact ? 2 : 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (tall) const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool isDark;
  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryAccent = BrandPalette.accent(primary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              letterSpacing: -0.5,
            ),
          ),
          if (action != null)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  '$action →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? primaryAccent : primary,
                  ),
                ),
              ),
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
  final VoidCallback? onTap;
  const _AttentionCard({
    required this.nome,
    required this.titulo,
    required this.subt,
    required this.acao,
    this.objetivo,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final chrome = ShellChrome.forDark(isDark);
    final cardBg = chrome.cardFill;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final accent = EagleTokens.bad; // simplificado para overdue

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 240,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.line,
            width: 1,
          ),
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
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      Text(
                        objetivo?.trim().isNotEmpty == true
                            ? objetivo!.trim()
                            : 'Objetivo não definido',
                        style: TextStyle(fontSize: 11, color: mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                Text(
                  titulo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.2, color: ink, height: 1.25),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '$acao →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ],
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
    final chrome = ShellChrome.forDark(isDark);
    final cardBg = chrome.cardFill;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark
                    ? EagleTokens.darkLine
                    : EagleTokens.line.withValues(alpha: 0.85),
            width: 1,
          ),
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
                    (isDark ? primaryAccent : primary).withValues(
                      alpha: isDark ? 0.20 : 0.12,
                    ),
                    (isDark ? primaryAccent : primary).withValues(
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
                  color: isDark ? primaryAccent : primary,
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
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: mute.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolGroupLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _ToolGroupLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.75,
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

  const _CommandCenterSection({
    required this.isDark,
    required this.primary,
    required this.finData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final chrome = ShellChrome.forDark(isDark);
    final cardBg = chrome.cardFill;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

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
      if (alunosRisco > 0)
        _CommandActionItem(
          icon: 'alert-triangle',
          title: 'Recuperar aderência',
          subtitle: '$alunosRisco aluno${alunosRisco == 1 ? '' : 's'} em risco',
          route: '/dashboard/qualidade',
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
      if (filaAcoes.where((a) => a.tipo != 'IA_COPILOTO').isNotEmpty)
        _CommandActionItem(
          icon: 'zap',
          title: 'Executar próxima ação',
          subtitle:
              filaAcoes.firstWhere((a) => a.tipo != 'IA_COPILOTO').descricao,
          route:
              filaAcoes
                      .firstWhere((a) => a.tipo != 'IA_COPILOTO')
                      .acaoUrl
                      .startsWith('/')
                  ? filaAcoes.firstWhere((a) => a.tipo != 'IA_COPILOTO').acaoUrl
                  : '/dashboard/personal',
          tone: _CommandActionTone.primary,
        ),
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
      required String icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return SizedBox(
        width: 178,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: ShellChrome.forDark(isDark).panel(radius: 20),
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
                      child: FxIcon(name: icon, size: 17, color: primary),
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
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'A melhor próxima ação para proteger receita e aderência.',
                    style: TextStyle(fontSize: 12.5, color: mute, height: 1.25),
                  ),
                ],
              ),
            ),
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
                          color: primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!isCommandPreparing) ...[
                        const SizedBox(width: 4),
                        FxIcon(name: 'chevron-right', size: 13, color: primary),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CommandActionPanel(
          isDark: isDark,
          primary: primary,
          loading: isCommandPreparing,
          actions: nextActions.take(2).toList(growable: false),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 82,
          child: ListView(
            key: const PageStorageKey('personal-command-modules'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              card(
                icon: 'zap',
                title: 'Copiloto',
                subtitle:
                    copilotAcoes.isEmpty
                        ? 'Sem tarefas'
                        : '${copilotAcoes.length} aberta${copilotAcoes.length == 1 ? '' : 's'}',
                onTap: () => context.push('/dashboard/command-center/copiloto'),
              ),
              card(
                icon: 'message-circle',
                title: 'Mensagens',
                subtitle: chatSubtitle,
                onTap: () => context.go('/chat/inbox'),
              ),
              card(
                icon: 'users',
                title: 'Alunos',
                subtitle: '$alunosAtivos ativos',
                onTap: () => context.go('/alunos'),
              ),
              card(
                icon: 'calendar',
                title: 'Agenda',
                subtitle: agendaSubtitle,
                onTap: () => context.go('/agenda'),
              ),
              card(
                icon: 'dollar-sign',
                title: 'Financeiro',
                subtitle: finSubtitle,
                onTap: () => context.go('/financeiro'),
              ),
            ],
          ),
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
  final chrome = ShellChrome.forDark(isDark);
  final cardBg = chrome.cardFill;
  final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
  final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
  final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

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
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: line.withValues(alpha: 0.86)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.12),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
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
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ordenadas pelo impacto de hoje.',
                          style: TextStyle(
                            color: mute,
                            fontSize: 12.2,
                            height: 1.2,
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FxIcon(name: 'route', size: 17, color: primary),
            const SizedBox(width: 8),
            Text(
              'Próximas ações',
              style: TextStyle(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              'impacto hoje',
              style: TextStyle(
                color: mute,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(
          color:
              isDark
                  ? EagleTokens.glassBorder
                  : EagleTokens.line.withValues(alpha: 0.85),
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
                        : EagleTokens.line.withValues(alpha: 0.75),
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.14 : 0.065),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Shimmer.fromColors(
            baseColor: primary.withValues(alpha: isDark ? 0.18 : 0.10),
            highlightColor: primary.withValues(alpha: isDark ? 0.32 : 0.18),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primary,
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final accent = switch (item.tone) {
      _CommandActionTone.hot => const Color(0xFFE5484D),
      _CommandActionTone.money => const Color(0xFF0E9F6E),
      _CommandActionTone.primary => primary,
    };
    return InkWell(
      onTap: onTap ?? () => context.go(item.route),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.10 : 0.075),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(15),
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
                    style: TextStyle(color: mute, fontSize: 11.6, height: 1.2),
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
    final primaryAccent = BrandPalette.accent(primary);
    final chrome = ShellChrome.forDark(isDark);
    final cardBg = chrome.cardFill;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(aderenciaTop3Provider);
        return async.when(
          loading:
              () => Container(
                height: 184,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                    width: 1,
                  ),
                ),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                    width: 1,
                  ),
                ),
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
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: FxIcon(
                          name: 'circle-check',
                          color: primary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sem check-ins nesta semana. Quando alunos treinarem, a aderência aparece aqui.',
                        style: TextStyle(color: mute, height: 1.3),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                  width: 1,
                ),
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
                                            : EagleTokens.line,
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
                                color: isDark ? primaryAccent : primary,
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
                                  a.nome,
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
                            color: isDark ? primaryAccent : primary,
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
    final ink = chromeOnDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = chromeOnDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
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
              style: GoogleFonts.outfit(
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
