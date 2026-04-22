import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../admin/screens/admin_screen.dart';
import '../../financeiro/data/financeiro_repository.dart';
import 'command_center_widget.dart';
import 'busca_global_widget.dart';
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
    } catch (_) {
      if (mounted) setState(() => _loadingFin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.backgroundDark : const Color(0xFFF1F5F9), // Fundo mais cinza claro estilo iOS
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.heroGradientDark.first : EagleTokens.heroGradientLight.first,
        elevation: 0,
        foregroundColor: Colors.white,
        title: dashboardAsync.when(
          data: (data) => Row(
            children: [
              if (data.logoUrl != null && data.logoUrl!.isNotEmpty) ...[
                CircleAvatar(backgroundImage: NetworkImage(data.logoUrl!), radius: 16),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FOCUX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                  Text('Bom dia, ${data.nomePersonal?.split(' ').first ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
                ],
              ),
            ],
          ),
          loading: () => const Text('FOCUX'),
          error: (_, __) => const Text('FOCUX'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const SizedBox(height: double.infinity, child: BuscaGlobalWidget()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => _buildShimmerLoading(context),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(commandCenterProvider);
            await _loadFin();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Receita Gradiente com bordas arredondadas (SaaS Mundial)
                Container(
                  decoration: BoxDecoration(
                    gradient: EagleTokens.heroGradient(dark: isDark),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECEITA - MÊS ATUAL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _loadingFin
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'R\$ ${_finData?.receitaMes.toStringAsFixed(0) ?? '0'}',
                                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
                                ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0, left: 4),
                            child: Text('/mês', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 3 Colunas de sub-métricas no Hero
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _HeroMiniStat(label: 'PREVISÃO', value: 'R\$ ${_finData?.previsaoReceita.toStringAsFixed(0) ?? '0'}'),
                            _HeroMiniStat(label: 'INADIMPL.', value: '${_finData?.totalInadimplentes ?? 0} alunos'),
                            _HeroMiniStat(label: 'TICKET', value: 'R\$ ${_finData?.ticketMedio.toStringAsFixed(0) ?? '0'}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Grid 2x2 Clean (Métricas Principais)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _CardMetrica(
                            valor: data.alunosAtivos.toString(),
                            titulo: 'Alunos ativos',
                            subtitulo: '${data.alunosInadimplentes} inadimplentes',
                            isDark: isDark,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _CardMetrica(
                            valor: '0',
                            titulo: 'Check-ins hoje',
                            subtitulo: '0 no mês',
                            isDark: isDark,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _CardMetrica(
                            valor: '0',
                            titulo: 'Risco alto',
                            subtitulo: '0 renovações próx.',
                            isDark: isDark,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _CardMetrica(
                            valor: '0%',
                            titulo: 'Aderência média',
                            subtitulo: 'últimos 30 dias',
                            isDark: isDark,
                          )),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Precisa de atenção
                      if (_finData != null && _finData!.vencimentosProximos.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Precisa de atenção', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(onPath: () {}, child: const Text('Ver tudo')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._finData!.vencimentosProximos.take(2).map((v) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? EagleTokens.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: EagleTokens.primary.withValues(alpha: 0.1),
                                    child: Text(v.alunoNome.substring(0, 1).toUpperCase(), style: const TextStyle(color: EagleTokens.primary, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v.alunoNome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const Text('Por inadimplência', style: TextStyle(color: EagleTokens.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('INADIMPLENTE', style: TextStyle(color: EagleTokens.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text('R\$ ${v.valor.toStringAsFixed(0)} pendente', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.whatsapp, size: 16),
                                      label: const Text('Lembrar via WhatsApp'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: EagleTokens.primary,
                                        side: const BorderSide(color: EagleTokens.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )),
                        const SizedBox(height: 32),
                      ],
                      
                      // ONBOARDING 3 MINUTOS (mantido do original)
                      const SetupOnboardingWidget(),
                      const SizedBox(height: 24),
                      
                      // Menu de Ferramentas
                      const Text('Ferramentas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _GridBtn(icon: Icons.people, label: 'Alunos', onTap: () => context.push('/alunos'), isDark: isDark),
                          _GridBtn(icon: Icons.fitness_center, label: 'Exercícios', onTap: () => context.push('/exercicios'), isDark: isDark),
                          _GridBtn(icon: Icons.list_alt, label: 'Treinos', onTap: () => context.push('/treinos'), isDark: isDark),
                          _GridBtn(icon: Icons.attach_money, label: 'Financeiro', onTap: () => context.push('/financeiro'), isDark: isDark),
                          _GridBtn(icon: Icons.calendar_month, label: 'Agenda', onTap: () => context.push('/agenda'), isDark: isDark),
                          _GridBtn(icon: Icons.dynamic_feed, label: 'Feed', onTap: () => context.push('/feed'), isDark: isDark),
                          _GridBtn(icon: Icons.security, label: 'Acessos', onTap: () => context.push('/admin/rbac'), isDark: isDark),
                          if (ref.watch(isAdminProvider))
                            _GridBtn(icon: Icons.admin_panel_settings, label: 'Admin', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())), isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 40),
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
  const _HeroMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CardMetrica extends StatelessWidget {
  final String titulo, valor, subtitulo;
  final bool isDark;
  const _CardMetrica({required this.titulo, required this.valor, required this.subtitulo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitulo, style: const TextStyle(color: EagleTokens.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GridBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool isDark;
  const _GridBtn({required this.icon, required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? EagleTokens.outlineDark : Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: EagleTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: EagleTokens.primary),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
