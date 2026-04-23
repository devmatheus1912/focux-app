import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../admin/screens/admin_screen.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';

class PersonalDashboardScreen extends ConsumerStatefulWidget {
  const PersonalDashboardScreen({super.key});

  @override
  ConsumerState<PersonalDashboardScreen> createState() => _PersonalDashboardScreenState();
}

class _PersonalDashboardScreenState extends ConsumerState<PersonalDashboardScreen> {
  FinanceiroDashboard? _finData;
  bool _loadingFin = true;

  @override
  void initState() {
    super.initState();
    _loadFin();
  }

  Future<void> _loadFin() async {
    try {
      final data = await FinanceiroRepository(ref.read(apiClientProvider)).dashboard();
      if (mounted) setState(() { _finData = data; _loadingFin = false; });
    } catch (e) { debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loadingFin = false);
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
        data: (data) => RefreshIndicator(
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
                                    text: 'Bom dia, ${data.nomePersonal?.split(' ').first ?? ''}',
                                    style: TextStyle(
                                      color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                final currentMode = ref.read(themeModeProvider);
                                ref.read(themeModeProvider.notifier).state = 
                                  currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                  border: isDark ? null : Border.all(color: EagleTokens.line),
                                ),
                                child: Icon(
                                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                  size: 20, 
                                  color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => context.push('/alertas'), // Rota de notificações
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                  border: isDark ? null : Border.all(color: EagleTokens.line),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.notifications_none, size: 20, color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
                                    Positioned(
                                      top: 8,
                                      right: 9,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: EagleTokens.brand,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isDark ? EagleTokens.darkCard : EagleTokens.card, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => context.push('/perfil'), // Rota de perfil do personal
                              borderRadius: BorderRadius.circular(18),
                              child: data.logoUrl != null && data.logoUrl!.isNotEmpty
                                  ? CircleAvatar(backgroundImage: NetworkImage(data.logoUrl!), radius: 18)
                                  : CircleAvatar(
                                      radius: 18,
                                      backgroundColor: EagleTokens.brand,
                                      child: Text(
                                        data.nomePersonal?.substring(0, 1).toUpperCase() ?? 'F',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: isDark
                          ? const LinearGradient(colors: [Color(0xFF1C3273), Color(0xFF0F1E4A)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2B4A9E).withValues(alpha: 0.4),
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
                        const Text('RECEITA · ABRIL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            _loadingFin
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    'R\$ ${_finData?.receitaMes.toStringAsFixed(0) ?? '0'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w600, letterSpacing: -1, height: 1),
                                  ),
                            const SizedBox(width: 6),
                            const Text('/ mês', style: TextStyle(color: Colors.white54, fontSize: 13)),
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
                            widthFactor: 0.71, // Simulando a progressão para demo
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
                            _HeroMiniStat(label: 'PREVISÃO', value: 'R\$ ${_finData?.previsaoReceita.toStringAsFixed(0) ?? '0'}'),
                            Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                            _HeroMiniStat(
                                label: 'INADIMPL.',
                                value: '${_finData?.totalInadimplentes ?? 0}',
                                suffix: ' alunos'),
                            Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                            _HeroMiniStat(label: 'TICKET', value: 'R\$ ${_finData?.ticketMedio.toStringAsFixed(0) ?? '0'}'),
                          ],
                        ),
                      ],
                    ),
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
                        sub: '${data.totalAlunos - data.alunosAtivos} inativos',
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
              if (_finData != null && _finData!.vencimentosProximos.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: _SectionTitle(title: 'Precisa de atenção', action: 'Ver tudo', isDark: isDark),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _finData!.vencimentosProximos.take(3).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final v = _finData!.vencimentosProximos[index];
                        return _AttentionCard(
                          nome: v.alunoNome,
                          tipo: 'overdue',
                          titulo: 'Inadimplente',
                          subt: 'R\$ ${v.valor.toStringAsFixed(0)} pendente',
                          acao: 'Cobrar',
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ),
              ],

              // ATALHOS / FERRAMENTAS
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _SectionTitle(title: 'Ferramentas', isDark: isDark),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: [
                      _ShortcutBtn(icon: Icons.people, label: 'Alunos', isDark: isDark, onTap: () => context.push('/alunos')),
                      _ShortcutBtn(icon: Icons.fitness_center, label: 'Exercícios', isDark: isDark, onTap: () => context.push('/exercicios')),
                      _ShortcutBtn(icon: Icons.list_alt, label: 'Treinos', isDark: isDark, onTap: () => context.push('/treinos')),
                      _ShortcutBtn(icon: Icons.attach_money, label: 'Financeiro', isDark: isDark, onTap: () => context.push('/financeiro')),
                      _ShortcutBtn(icon: Icons.calendar_month, label: 'Agenda', isDark: isDark, onTap: () => context.push('/agenda')),
                      _ShortcutBtn(icon: Icons.dynamic_feed, label: 'Feed', isDark: isDark, onTap: () => context.push('/feed')),
                      _ShortcutBtn(icon: Icons.security, label: 'Acessos', isDark: isDark, onTap: () => context.push('/admin/rbac')),
                      if (ref.watch(isAdminProvider))
                        _ShortcutBtn(icon: Icons.admin_panel_settings, label: 'Admin', isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()))),
                    ],
                  ),
                ),
              ),
            ],
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
            baseColor: const Color(0xFFD1D5DB)!,
            highlightColor: const Color(0xFFF3F4F6)!,
            child: Container(
              height: 200,
              color: Colors.white,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Shimmer.fromColors(baseColor: const Color(0xFFD1D5DB)!, highlightColor: const Color(0xFFF3F4F6)!, child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))))),
                      const SizedBox(width: 12),
                      Expanded(child: Shimmer.fromColors(baseColor: const Color(0xFFD1D5DB)!, highlightColor: const Color(0xFFF3F4F6)!, child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Shimmer.fromColors(baseColor: const Color(0xFFD1D5DB)!, highlightColor: const Color(0xFFF3F4F6)!, child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))))),
                      const SizedBox(width: 12),
                      Expanded(child: Shimmer.fromColors(baseColor: const Color(0xFFD1D5DB)!, highlightColor: const Color(0xFFF3F4F6)!, child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))))),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5, letterSpacing: 0.08, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value),
              if (suffix != null) TextSpan(text: suffix, style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w400)),
            ],
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
  const _QuickTile({required this.icon, required this.label, required this.value, required this.sub, required this.accent, required this.isDark});

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
        boxShadow: isDark ? null : [BoxShadow(color: EagleTokens.line, blurRadius: 0, spreadRadius: 0.5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF8DA4E2).withValues(alpha: 0.15) : EagleTokens.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: isDark ? const Color(0xFF8DA4E2) : accent),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: ink, height: 1, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: ink)),
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
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.darkInk : EagleTokens.ink, letterSpacing: -0.5)),
          if (action != null)
            Text('$action →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand)),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final String nome, tipo, titulo, subt, acao;
  final bool isDark;
  const _AttentionCard({required this.nome, required this.tipo, required this.titulo, required this.subt, required this.acao, required this.isDark});

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
        boxShadow: isDark ? null : [BoxShadow(color: EagleTokens.line, blurRadius: 0, spreadRadius: 0.5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: EagleTokens.brand, child: Text(nome.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
                    Text('Objetivo não definido', style: TextStyle(fontSize: 11, color: mute)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
              const SizedBox(width: 5),
              Text(titulo.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subt, style: TextStyle(fontSize: 12.5, color: ink, height: 1.35)),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : EagleTokens.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('$acao →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : EagleTokens.brand)),
          ),
        ],
      ),
    );
  }
}

class _ShortcutBtn extends StatelessWidget {
  final IconData icon; final String label; final String? sub; final VoidCallback onTap; final bool isDark;
  const _ShortcutBtn({required this.icon, required this.label, this.sub, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : [BoxShadow(color: EagleTokens.line, blurRadius: 0, spreadRadius: 0.5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand),
            const Spacer(),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink, height: 1.2)),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!, style: TextStyle(fontSize: 10.5, color: mute)),
            ]
          ],
        ),
      ),
    );
  }
}
