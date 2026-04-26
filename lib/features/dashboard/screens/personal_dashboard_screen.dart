import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_logo.dart';
import '../../../core/widgets/fx_sparkline.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';

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
    _counterAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut),
    );
    _loadFin();
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFin() async {
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
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) {
        setState(() {
          _finData = FinanceiroDashboard(
            receitaMes: 8420,
            receitaAcumulada: 39000,
            ticketMedio: 349,
            totalInadimplentes: 2,
            previsaoReceita: 11750,
            vencimentosProximos: [
              VencimentoItem(
                mensalidadeId: 1,
                alunoNome: 'Rafael Medeiros',
                valor: 450,
                mesReferencia: 'abr/26',
                status: 'ATRASADO',
              ),
              VencimentoItem(
                mensalidadeId: 2,
                alunoNome: 'Juliana Torres',
                valor: 380,
                mesReferencia: 'abr/26',
                status: 'ATRASADO',
              ),
              VencimentoItem(
                mensalidadeId: 3,
                alunoNome: 'Lucas Andrade',
                valor: 280,
                mesReferencia: 'mai/26',
                status: 'PENDENTE',
              ),
            ],
            topAlunos: const [],
            evolucaoMensal: const [],
          );
          _loadingFin = false;
        });
        _counterAnim = Tween<double>(
          begin: 0,
          end: _finData!.receitaMes,
        ).animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
        _counterCtrl.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.backgroundDark : EagleTokens.paper,
      body: dashboardAsync.when(
        loading: () => _buildShimmerLoading(context),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data:
            (data) {
              // Computed values for hero card
              final monthNames = [
                'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
                'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
              ];
              final mes = monthNames[DateTime.now().month - 1];
              final pendente = ((_finData?.previsaoReceita ?? 0) -
                      (_finData?.receitaMes ?? 0))
                  .clamp(0.0, double.infinity);

              return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardProvider);
                ref.invalidate(commandCenterProvider);
                await _loadFin();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverSafeArea(
                    bottom: false,
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
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
                                    ],
                                  ),
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
                            Row(
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
                                    child: Icon(
                                      isDark
                                          ? Icons.light_mode_outlined
                                          : Icons.dark_mode_outlined,
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
                                        '/alertas',
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
                                        Icon(
                                          Icons.notifications_none,
                                          size: 20,
                                          color:
                                              isDark
                                                  ? EagleTokens.darkInk
                                                  : EagleTokens.ink,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 9,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: EagleTokens.brand,
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
                                            backgroundColor: EagleTokens.brand,
                                            child: Text(
                                              data.nomePersonal
                                                      ?.substring(0, 1)
                                                      .toUpperCase() ??
                                                  'F',
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
                  ),

                  // HERO CARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AnimatedBuilder(
                        animation: _gradientCtrl,
                        builder: (ctx, _) {
                          final angle =
                              _gradientCtrl.value * 2 * math.pi;
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
                                    : const [
                                      EagleTokens.brand,
                                      EagleTokens.brandDeep,
                                    ],
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
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
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
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
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
                                              fontWeight: FontWeight.w600,
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
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor:
                                    0.71, // Simulando a progressão para demo
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _HeroMiniStat(
                                  label: 'PENDENTE',
                                  value:
                                      'R\$ ${pendente.toInt()}',
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                _HeroMiniStat(
                                  label: 'INADIMPL.',
                                  value: '${_finData?.totalInadimplentes ?? 0}',
                                  suffix: ' alunos',
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white.withValues(alpha: 0.15),
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
                          );
                        },
                      ),
                    ),
                  ),

                  // GRID METRICAS
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.5,
                        children: [
                          _QuickTile(
                            icon: Icons.people,
                            label: 'Alunos ativos',
                            value: data.alunosAtivos.toString(),
                            sub:
                                '${data.totalAlunos - data.alunosAtivos} inativos',
                            accent: EagleTokens.brand,
                            isDark: isDark,
                          ),
                          _QuickTile(
                            icon: Icons.check_circle_outline,
                            label: 'Check-ins hoje',
                            value: '0',
                            sub: '0 no mês',
                            accent: EagleTokens.good,
                            isDark: isDark,
                          ),
                          _QuickTile(
                            icon: Icons.warning_amber_rounded,
                            label: 'Risco alto',
                            value: '0',
                            sub: '0 renovações próx.',
                            accent: EagleTokens.warn,
                            isDark: isDark,
                          ),
                          _QuickTile(
                            icon: Icons.local_fire_department_outlined,
                            label: 'Aderência média',
                            value: '0%',
                            sub: 'últimos 30 dias',
                            accent: EagleTokens.brand,
                            isDark: isDark,
                          ),
                        ],
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
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                    child: _SectionTitle(title: 'Atalhos', isDark: isDark),
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
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.9,
                        children: [
                          _ShortcutBtn(
                            icon: Icons.auto_awesome,
                            label: 'Gerar treino',
                            isDark: isDark,
                            onTap: () => context.go('/ia/copiloto'),
                          ),
                          _ShortcutBtn(
                            icon: Icons.person_add_outlined,
                            label: 'Novo aluno',
                            isDark: isDark,
                            onTap: () => context.push('/alunos/novo'),
                          ),
                          _ShortcutBtn(
                            icon: Icons.calendar_month,
                            label: 'Agenda',
                            isDark: isDark,
                            onTap: () => context.push('/agenda'),
                          ),
                          _ShortcutBtn(
                            icon: Icons.chat_bubble_outline,
                            label: 'Mensagens',
                            isDark: isDark,
                            onTap: () => context.push('/chat/aluno'),
                          ),
                          _ShortcutBtn(
                            icon: Icons.pix,
                            label: 'Cobrar PIX',
                            isDark: isDark,
                            onTap: () => context.go('/financeiro'),
                          ),
                          _ShortcutBtn(
                            icon: Icons.people_outline,
                            label: 'Leads',
                            isDark: isDark,
                            onTap: () => context.push('/leads'),
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
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: const Color(0xFFD1D5DB),
            highlightColor: const Color(0xFFF3F4F6),
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
                          baseColor: const Color(0xFFD1D5DB),
                          highlightColor: const Color(0xFFF3F4F6),
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
                          baseColor: const Color(0xFFD1D5DB),
                          highlightColor: const Color(0xFFF3F4F6),
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
                          baseColor: const Color(0xFFD1D5DB),
                          highlightColor: const Color(0xFFF3F4F6),
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
                          baseColor: const Color(0xFFD1D5DB),
                          highlightColor: const Color(0xFFF3F4F6),
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
  final IconData icon;
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border:
            isDark
                ? null
                : Border.all(color: EagleTokens.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? const Color(0xFF8DA4E2).withValues(alpha: 0.15)
                      : EagleTokens.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFF8DA4E2) : accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: ink,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
          const SizedBox(height: 1),
          Text(sub, style: TextStyle(fontSize: 11, color: mute)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final bool isDark;
  const _SectionTitle({required this.title, this.action, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
            Text(
              '$action →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand,
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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final accent = EagleTokens.bad; // simplificado para overdue

    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border:
            isDark
                ? null
                : Border.all(color: EagleTokens.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: EagleTokens.brand,
                child: Text(
                  nome.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : EagleTokens.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$acao →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : EagleTokens.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutBtn extends StatelessWidget {
  final IconData icon;
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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border:
              isDark ? null : Border.all(color: EagleTokens.line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand,
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AderenciaSemanaWidget extends StatelessWidget {
  final bool isDark;
  const _AderenciaSemanaWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    // Fake data to represent the 3 top active students
    final alunos = [
      {
        'nome': 'Marcos Silva',
        'obj': 'Hipertrofia',
        'treinos': '4',
        'ad': '92',
        'spark': [0.2, 0.4, 0.3, 0.8, 1.0],
      },
      {
        'nome': 'Juliana Costa',
        'obj': 'Emagrecimento',
        'treinos': '3',
        'ad': '85',
        'spark': [0.5, 0.6, 0.8, 0.7, 0.9],
      },
      {
        'nome': 'Roberto Carlos',
        'obj': 'Força',
        'treinos': '5',
        'ad': '78',
        'spark': [1.0, 0.7, 0.5, 0.6, 0.8],
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border:
            isDark ? null : Border.all(color: EagleTokens.line, width: 1),
      ),
      child: Column(
        children: List.generate(alunos.length, (index) {
          final a = alunos[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border:
                  index < alunos.length - 1
                      ? Border(
                        bottom: BorderSide(
                          color:
                              isDark ? EagleTokens.darkLine : EagleTokens.line,
                          width: 0.5,
                        ),
                      )
                      : null,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF8DA4E2).withValues(alpha: 0.15)
                          : EagleTokens.brandSoft,
                  child: Text(
                    (a['nome'] as String).substring(0, 1),
                    style: TextStyle(
                      color:
                          isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['nome'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${a['obj']} · ${a['treinos']} treinos',
                        style: TextStyle(fontSize: 12, color: mute),
                      ),
                    ],
                  ),
                ),
                // Sparkline
                FxSparkline(
                  data: a['spark'] as List<double>,
                  width: 56,
                  height: 22,
                  color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand,
                ),
                const SizedBox(width: 14),
                // Percentage
                SizedBox(
                  width: 40,
                  child: Text(
                    '${a['ad']}%',
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
  }
}
