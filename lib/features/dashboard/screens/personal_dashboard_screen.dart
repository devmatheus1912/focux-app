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

    return Scaffold(
      appBar: AppBar(
        title: dashboardAsync.when(
          data: (data) => data.logoUrl != null && data.logoUrl!.isNotEmpty
              ? Image.network(data.logoUrl!, height: 32, errorBuilder: (_, __, ___) => Text(data.nomePersonal ?? 'Visão Geral'))
              : Text(data.nomePersonal ?? 'Visão Geral'),
          loading: () => const Text('Visão Geral'),
          error: (_, __) => const Text('Visão Geral'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Busca rápida',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const SizedBox(
                height: double.infinity,
                child: BuscaGlobalWidget(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
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
                // Hero Receita Gradiente
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 24, bottom: 40, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Receita do Mês', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      _loadingFin
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'R\$ ${_finData?.receitaMes.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up, color: EagleTokens.success, size: 16),
                                const SizedBox(width: 4),
                                Text('Previsão: R\$ ${_finData?.previsaoReceita.toStringAsFixed(2) ?? '0.00'}', 
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Grid 2x2 Transform upward
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _CardMetrica(
                              titulo: 'Alunos Ativos',
                              valor: data.alunosAtivos.toString(),
                              icone: Icons.people,
                              cor: EagleTokens.primary,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _CardMetrica(
                              titulo: 'Inadimplentes',
                              valor: _finData?.totalInadimplentes.toString() ?? '0',
                              icone: Icons.warning_amber_rounded,
                              cor: EagleTokens.danger,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _CardMetrica(
                              titulo: 'Ticket Médio',
                              valor: 'R\$ ${_finData?.ticketMedio.toStringAsFixed(0) ?? '0'}',
                              icone: Icons.receipt_long,
                              cor: EagleTokens.primary,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _CardMetrica(
                              titulo: 'Plano atual',
                              valor: data.planoAtual,
                              icone: Icons.workspace_premium,
                              cor: EagleTokens.warning,
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // ONBOARDING 3 MINUTOS
                        const SetupOnboardingWidget(),
                        
                        // CENTRAL DE COMANDO (Command Center)
                        const CommandCenterWidget(),
                        
                        // Precisa de Atenção + WhatsApp CTA
                        if (_finData != null && _finData!.vencimentosProximos.isNotEmpty) ...[
                          Text('Precisa de Atenção', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ..._finData!.vencimentosProximos.take(3).map((v) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: EagleTokens.danger, child: Icon(Icons.warning, color: Colors.white, size: 20)),
                              title: Text(v.alunoNome, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Atrasado: R\$ ${v.valor.toStringAsFixed(2)}', style: const TextStyle(color: EagleTokens.danger)),
                              trailing: IconButton(
                                icon: const Icon(Icons.message, color: EagleTokens.success),
                                tooltip: 'Cobrar via WhatsApp',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrindo WhatsApp...')));
                                },
                              ),
                            ),
                          )),
                          const SizedBox(height: 24),
                        ],
                        
                        // Perfil Profissional Destaque (P12)
                        if (data.nomePersonal != null && data.nomePersonal!.isNotEmpty) ...[
                          Card(
                            margin: const EdgeInsets.only(bottom: 24),
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: data.logoUrl != null ? NetworkImage(data.logoUrl!) : null,
                                    child: data.logoUrl == null ? const Icon(Icons.person, size: 30) : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data.nomePersonal!, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                        if (data.descricaoProfissional != null)
                                          Text(data.descricaoProfissional!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                                        if (data.instagram != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.link, size: 14),
                                              const SizedBox(width: 4),
                                              Text(data.instagram!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        // Menu Principal (Grid ou List)
                        Text('Ferramentas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            _GridBtn(icon: Icons.people, label: 'Alunos', onTap: () => context.push('/alunos')),
                            _GridBtn(icon: Icons.fitness_center, label: 'Exercícios', onTap: () => context.push('/exercicios')),
                            _GridBtn(icon: Icons.list_alt, label: 'Treinos', onTap: () => context.push('/treinos')),
                            _GridBtn(icon: Icons.attach_money, label: 'Financeiro', onTap: () => context.push('/financeiro')),
                            _GridBtn(icon: Icons.calendar_month, label: 'Agenda', onTap: () => context.push('/agenda')),
                            _GridBtn(icon: Icons.dynamic_feed, label: 'Feed', onTap: () => context.push('/feed')),
                            _GridBtn(icon: Icons.people_alt, label: 'Funil', onTap: () => context.push('/leads')),
                            _GridBtn(icon: Icons.warning_amber_rounded, label: 'Alertas', onTap: () => context.push('/alertas')),
                            _GridBtn(icon: Icons.psychology, label: 'Copiloto IA', onTap: () => context.push('/ia/copiloto')),
                            _GridBtn(icon: Icons.speed, label: 'Qualidade', onTap: () => context.push('/dashboard/qualidade')),
                            _GridBtn(icon: Icons.security, label: 'Acessos', onTap: () => context.push('/admin/rbac')),
                            if (ref.watch(isAdminProvider))
                              _GridBtn(icon: Icons.admin_panel_settings, label: 'Admin', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()))),
                          ],
                        ),
                      ],
                    ),
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

class _CardMetrica extends StatelessWidget {
  final String titulo, valor;
  final IconData icone;
  final Color cor;
  const _CardMetrica({required this.titulo, required this.valor, required this.icone, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 12),
            Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(titulo, style: const TextStyle(color: EagleTokens.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _GridBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _GridBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
