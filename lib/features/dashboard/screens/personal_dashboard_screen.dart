import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_logo.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_sparkline.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/aderencia_provider.dart';
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
  late Animation<double> _counterAnim;

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
    _counterAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _loadFin();
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _counterCtrl.dispose();
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
    final primaryDeep = BrandPalette.deep(primary);
    final dashboardAsync = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alunosAsync = ref.watch(alunosProvider);
    final historicoCheckinsAsync = ref.watch(historicoCheckinProvider);
    final aderenciaAsync = ref.watch(aderenciaTop3Provider);
    final notificacoesNaoLidas =
        ref.watch(notificacoesNaoLidasProvider).valueOrNull ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? EagleTokens.backgroundDark : EagleTokens.paper,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? EagleTokens.backgroundDark : EagleTokens.paper,
        body: SafeArea(
          bottom: false,
          child: dashboardAsync.when(
            loading: () => _buildShimmerLoading(context),
            error: (e, _) => Center(child: Text(friendlyError(e))),
            data: (data) {
              final screenWidth = MediaQuery.sizeOf(context).width;
              final isCompactPhone = screenWidth < 390;
              final shortcutAspectRatio = isCompactPhone ? 2.35 : 2.65;

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
              final totalAlunos = alunosAsync.maybeWhen(
                data: (alunos) => alunos.length,
                orElse: () => data.totalAlunos,
              );
              final riscoAlto = alunosAsync.maybeWhen(
                data: (alunos) => alunos.where((a) => a.emRisco).length,
                orElse: () => 0,
              );

              // BUG-07: aderência média real dos top-3 alunos
              final aderenciaMediaStr = aderenciaAsync.maybeWhen(
                data: (lista) {
                  if (lista.isEmpty) return '—';
                  final media =
                      lista
                          .map((a) => a.aderenciaPercent)
                          .reduce((a, b) => a + b) ~/
                      lista.length;
                  return '$media%';
                },
                orElse: () => '—',
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
                                    iconSize: 28,
                                    showLabel: true,
                                    horizontal: true,
                                    light: isDark,
                                  ),
                                  const SizedBox(height: 10),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(text: 'Hoje · '),
                                        TextSpan(
                                          text:
                                              'Bom dia, ${data.nomePersonal?.split(' ').first ?? ''}',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? EagleTokens.darkInk
                                                    : EagleTokens.ink,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              riscoAlto > 0
                                                  ? ' · $riscoAlto precisam de você'
                                                  : ' · operação estável',
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDark
                                              ? EagleTokens.darkInkMute
                                              : EagleTokens.inkMute,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    final currentMode = ref.read(
                                      themeModeProvider,
                                    );
                                    ref.read(themeModeProvider.notifier).state =
                                        currentMode == ThemeMode.dark
                                            ? ThemeMode.light
                                            : ThemeMode.dark;
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                              : Colors.white,
                                      border:
                                          isDark
                                              ? null
                                              : Border.all(
                                                color: EagleTokens.line,
                                              ),
                                    ),
                                    child: FxIcon(
                                      name: isDark ? 'sun' : 'moon',
                                      size: 20,
                                      color:
                                          isDark
                                              ? EagleTokens.darkInk
                                              : EagleTokens.ink,
                                    ),
                                  ),
                                ),
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
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                              : Colors.white,
                                      border:
                                          isDark
                                              ? null
                                              : Border.all(
                                                color: EagleTokens.line,
                                              ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        FxIcon(
                                          name: 'bell',
                                          size: 20,
                                          color:
                                              isDark
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
                                                      isDark
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
                                                fontWeight: FontWeight.bold,
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
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: LinearGradient(
                                  colors:
                                      isDark
                                          ? const [
                                            Color(0xFF1C3273),
                                            Color(0xFF0F1E4A),
                                          ]
                                          : [primary, primaryDeep],
                                  begin: begin,
                                  end: end,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2B4A9E,
                                    ).withValues(alpha: 0.4),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Receita · $mes',
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
                                          ? 'Faltam R\$ ${pendente.toInt()} para fechar a meta.'
                                          : 'Meta do mês sob controle.',
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
                                            ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : AnimatedBuilder(
                                              animation: _counterAnim,
                                              builder:
                                                  (ctx, _) => Text(
                                                    'R\$ ${_counterAnim.value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 44,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: -1,
                                                      height: 1,
                                                    ),
                                                  ),
                                            ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '/ R\$ ${_finData?.previsaoReceita.toStringAsFixed(0) ?? '--'}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                            );
                          },
                        ),
                      ),
                    ),

                    // PULSO DO DIA
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 0, 20),
                        child: SizedBox(
                          height: 96,
                          child: ListView(
                            key: const PageStorageKey('personal-pulse-strip'),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(right: 16),
                            children: [
                              _QuickTile(
                                icon: 'users',
                                label: 'Alunos ativos',
                                value: alunosAtivos.toString(),
                                sub:
                                    '${math.max(0, totalAlunos - alunosAtivos)} inativos',
                                accent: primary,
                                isDark: isDark,
                              ),
                              _QuickTile(
                                icon: 'circle-check',
                                label: 'Check-ins hoje',
                                value: checkinsHoje.toString(),
                                sub: 'histórico de treinos',
                                accent: EagleTokens.good,
                                isDark: isDark,
                              ),
                              _QuickTile(
                                icon: 'alert-triangle',
                                label: 'Risco alto',
                                value: riscoAlto.toString(),
                                sub: 'precisam atenção',
                                accent: EagleTokens.warn,
                                isDark: isDark,
                              ),
                              _QuickTile(
                                icon: 'flame',
                                label: 'Aderência média',
                                value: aderenciaMediaStr,
                                sub: 'últimos 7 dias',
                                accent: primary,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // CENTRAL DE COMANDO
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _CommandCenterSection(
                          isDark: isDark,
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
                    if (_finData != null &&
                        _finData!.vencimentosProximos.isNotEmpty) ...[
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Precisa de atenção',
                          action: 'Ver tudo',
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 160,
                          child: ListView.separated(
                            key: const PageStorageKey(
                              'personal-attention-rail',
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                _finData!.vencimentosProximos.take(3).length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final v = _finData!.vencimentosProximos[index];
                              return _AttentionCard(
                                nome: v.alunoNome,
                                tipo: 'overdue',
                                titulo: 'Inadimplente',
                                subt:
                                    'R\$ ${v.valor.toStringAsFixed(0)} pendente',
                                acao: 'Cobrar',
                                isDark: isDark,
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
                        isDark: isDark,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _AderenciaSemanaWidget(isDark: isDark),
                      ),
                    ),

                    // ATALHOS — 6 quick action shortcuts (design spec)
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: 'Ferramentas',
                        isDark: isDark,
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
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: shortcutAspectRatio,
                          children: [
                            _ShortcutBtn(
                              icon: 'spark',
                              label: 'IA Copiloto',
                              isDark: isDark,
                              onTap: () => context.go('/ia/copiloto'),
                            ),
                            _ShortcutBtn(
                              icon: 'plus',
                              label: 'Novo aluno',
                              isDark: isDark,
                              onTap: () => context.push('/alunos/novo'),
                            ),
                            _ShortcutBtn(
                              icon: 'calendar',
                              label: 'Agenda',
                              isDark: isDark,
                              onTap: () => context.go('/agenda'),
                            ),
                            _ShortcutBtn(
                              icon: 'chat',
                              label: 'Mensagens',
                              isDark: isDark,
                              onTap: () => context.push('/chat/inbox'),
                            ),
                            _ShortcutBtn(
                              icon: 'article',
                              label: 'Feed',
                              isDark: isDark,
                              onTap: () => context.push('/feed'),
                            ),
                            _ShortcutBtn(
                              icon: 'pix',
                              label: 'Financeiro',
                              isDark: isDark,
                              onTap: () => context.go('/financeiro'),
                            ),
                            _ShortcutBtn(
                              icon: 'trend',
                              label: 'Leads',
                              isDark: isDark,
                              onTap: () => context.push('/leads'),
                            ),
                            _ShortcutBtn(
                              icon: 'spark',
                              label: 'Qualidade',
                              isDark: isDark,
                              onTap: () => context.push('/dashboard/qualidade'),
                            ),
                            _ShortcutBtn(
                              icon: 'dumbbell',
                              label: 'Exercicios',
                              isDark: isDark,
                              onTap: () => context.push('/exercicios'),
                            ),
                            _ShortcutBtn(
                              icon: 'bell',
                              label: 'Broadcasts',
                              isDark: isDark,
                              onTap: () => context.push('/broadcasts'),
                            ),
                            _ShortcutBtn(
                              icon: 'chat',
                              label: 'Suporte',
                              isDark: isDark,
                              onTap: () => context.push('/suporte'),
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
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: EagleTokens.line,
            highlightColor: EagleTokens.lineSoft,
            child: Container(height: 200, color: Colors.white),
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: EagleTokens.line,
                          highlightColor: EagleTokens.lineSoft,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: EagleTokens.line,
                          highlightColor: EagleTokens.lineSoft,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: EagleTokens.line,
                          highlightColor: EagleTokens.lineSoft,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: EagleTokens.line,
                          highlightColor: EagleTokens.lineSoft,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
        ],
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String icon;
  final String label, value, sub;
  final Color accent;
  final bool isDark;
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      width: 154,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.22 : 0.13),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF0B1220).withValues(alpha: 0.035),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(child: FxIcon(name: icon, size: 16, color: accent)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    height: 1,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(fontSize: 10.5, color: mute, height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
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
  final String nome, tipo, titulo, subt, acao;
  final bool isDark;
  const _AttentionCard({
    required this.nome,
    required this.tipo,
    required this.titulo,
    required this.subt,
    required this.acao,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final accent = EagleTokens.bad; // simplificado para overdue

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
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
                      'Objetivo não definido',
                      style: TextStyle(fontSize: 11, color: mute),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            style: TextStyle(fontSize: 12.5, color: ink, height: 1.35),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isDark ? primaryAccent : primary).withValues(
                  alpha: isDark ? 0.14 : 0.09,
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
          ],
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

  const _CommandCenterSection({
    required this.isDark,
    required this.primary,
    required this.finData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    // Chat inbox — count total unread messages
    final chatAsync = ref.watch(chatInboxProvider);
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
    final commandAsync = ref.watch(commandCenterProvider);
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
    final cobrancasPendentes = commandAsync.maybeWhen(
      data: (cc) => cc.cobrancasPendentes.length,
      orElse: () => finData?.totalInadimplentes ?? 0,
    );
    final nextActions = <_CommandActionItem>[
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
      if (filaAcoes.isNotEmpty)
        _CommandActionItem(
          icon: 'zap',
          title: 'Executar próxima ação',
          subtitle: filaAcoes.first.descricao,
          route:
              filaAcoes.first.acaoUrl.startsWith('/')
                  ? filaAcoes.first.acaoUrl
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
    if (nextActions.isEmpty) {
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
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: line.withValues(alpha: 0.78)),
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${nextActions.length} focos',
                style: TextStyle(
                  color: primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CommandActionPanel(
          isDark: isDark,
          primary: primary,
          actions: nextActions.take(3).toList(growable: false),
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
  final List<_CommandActionItem> actions;

  const _CommandActionPanel({
    required this.isDark,
    required this.primary,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line.withValues(alpha: 0.82)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF0B1220).withValues(alpha: 0.045),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 10),
          for (var index = 0; index < actions.length; index++) ...[
            _CommandActionTile(
              item: actions[index],
              isDark: isDark,
              primary: primary,
            ),
            if (index < actions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CommandActionTile extends StatelessWidget {
  final _CommandActionItem item;
  final bool isDark;
  final Color primary;

  const _CommandActionTile({
    required this.item,
    required this.isDark,
    required this.primary,
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
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.16 : 0.075),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.10)),
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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(aderenciaTop3Provider);
        return async.when(
          loading:
              () => Container(
                height: 180,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
                child: Text(
                  'Erro ao carregar aderência: $e',
                  style: TextStyle(color: mute),
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
                child: Text(
                  'Sem dados de check-in na semana.',
                  style: TextStyle(color: mute),
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
                  return Container(
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
                              fontWeight: FontWeight.bold,
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
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
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
