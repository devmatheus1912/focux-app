import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/admin_repository.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  AdminStats? _stats;
  List<AdminPersonal> _personais = [];
  AdminMonitor? _monitor;
  bool _loading = true;
  bool _loadingMonitor = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        final idx = _tabs.index;
        if ((idx == 1 || idx == 2) && _monitor == null && !_loadingMonitor) {
          _loadMonitor();
        }
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = AdminRepository(ref.read(apiClientProvider));
      final results = await Future.wait([repo.stats(), repo.listarPersonais()]);
      if (mounted) {
        setState(() {
          _stats = results[0] as AdminStats;
          _personais = results[1] as List<AdminPersonal>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
    _loadMonitor();
  }

  Future<void> _loadMonitor() async {
    if (!mounted) return;
    setState(() => _loadingMonitor = true);
    try {
      final repo = AdminRepository(ref.read(apiClientProvider));
      final monitor = await repo.monitor();
      if (mounted) {
        setState(() {
          _monitor = monitor;
          _loadingMonitor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMonitor = false);
    }
  }

  Future<void> _toggleAdmin(AdminPersonal p) async {
    try {
      await AdminRepository(ref.read(apiClientProvider)).toggleAdmin(p.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _resolverTicket(SuporteTicket ticket) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resolver Ticket #${ticket.id}',
              style: Theme.of(ctx).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(ticket.titulo,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Resposta do admin',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await AdminRepository(ref.read(apiClientProvider))
                      .resolverTicket(ticket.id, resposta: controller.text.isEmpty ? null : controller.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket resolvido!')),
                    );
                    _loadMonitor();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                }
              },
              child: const Text('Confirmar Resolução'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalRiscoDetalhes(PersonalRisco p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p.nome, style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(p.email, style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            _DetailRow(label: 'Plano', value: p.plano),
            _DetailRow(label: 'Total de Alunos', value: '${p.totalAlunos}'),
            _DetailRow(
              label: 'Inadimplentes',
              value: '${p.alunosInadimplentes}',
              valueColor: p.alunosInadimplentes > 0 ? EagleTokens.bad : null,
            ),
            _DetailRow(
              label: 'Check-ins (30 dias)',
              value: '${p.checkInsUltimos30Dias}',
              valueColor: p.checkInsUltimos30Dias < 5 ? EagleTokens.warn : null,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            Tab(icon: Icon(Icons.monitor_heart), text: 'Monitor'),
            Tab(icon: Icon(Icons.trending_down), text: 'Churn Watch'),
            Tab(icon: Icon(Icons.people), text: 'Personais'),
            Tab(icon: Icon(Icons.history), text: 'Auditoria'),
            Tab(icon: Icon(Icons.toggle_on), text: 'Feature Flags'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Modo claro' : 'Modo escuro',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _StatsTab(stats: _stats),
                _MonitorTab(
                  monitor: _monitor,
                  loading: _loadingMonitor,
                  onResolver: _resolverTicket,
                ),
                _ChurnWatchTab(
                  monitor: _monitor,
                  loading: _loadingMonitor,
                  onTap: _showPersonalRiscoDetalhes,
                ),
                _PersonaisTab(
                  personais: _personais,
                  onToggleAdmin: _toggleAdmin,
                ),
                const _AuditoriaTab(),
                const _FeatureFlagsTab(),
              ],
            ),
    );
  }
}

// ─── Tab 1: Stats ───────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final AdminStats? stats;
  const _StatsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const Center(child: Text('Sem dados'));
    final s = stats!;
    final plataformaSaudavel = true; // sem campo tickets na AdminStats — exibe positivo por padrão
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Plataforma Focux',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _MetricCard(
                label: 'Total Personais',
                value: '${s.totalPersonais}',
                icon: Icons.people,
                color: const Color(0xFF2B4A9E),
              ),
              _MetricCard(
                label: 'Total Alunos',
                value: '${s.totalAlunos}',
                icon: Icons.fitness_center,
                color: EagleTokens.good,
              ),
              _MetricCard(
                label: 'Admins',
                value: '${s.admins}',
                icon: Icons.admin_panel_settings,
                color: const Color(0xFF7C3AED),
              ),
              _StatusCard(saudavel: plataformaSaudavel),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool saudavel;
  const _StatusCard({required this.saudavel});

  @override
  Widget build(BuildContext context) {
    final color = saudavel ? EagleTokens.good : EagleTokens.warn;
    final icon = saudavel ? Icons.check_circle : Icons.warning_amber_rounded;
    final label = saudavel ? 'Plataforma Saudável' : 'Atenção Necessária';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Monitor (Suporte) ────────────────────────────────────────────────

class _MonitorTab extends StatelessWidget {
  final AdminMonitor? monitor;
  final bool loading;
  final Future<void> Function(SuporteTicket) onResolver;

  const _MonitorTab({
    required this.monitor,
    required this.loading,
    required this.onResolver,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (monitor == null) return const Center(child: Text('Sem dados de monitoramento.'));

    final m = monitor!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                _SummaryChip(
                  label: '${m.ticketsAbertos} Abertos',
                  color: EagleTokens.brand,
                ),
                _SummaryChip(
                  label: '${m.ticketsCriticos} Críticos',
                  color: EagleTokens.bad,
                ),
                _SummaryChip(
                  label: '${m.totalInadimplentes} Inadimplentes',
                  color: EagleTokens.warn,
                ),
              ],
            ),
          ),
        ),
        if (m.ultimosTickets.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('Nenhum ticket aberto.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _TicketCard(
                  ticket: m.ultimosTickets[i],
                  onResolver: onResolver,
                ),
                childCount: m.ultimosTickets.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SuporteTicket ticket;
  final Future<void> Function(SuporteTicket) onResolver;
  const _TicketCard({required this.ticket, required this.onResolver});

  Color _severidadeColor(String sev) {
    switch (sev.toUpperCase()) {
      case 'CRITICA':
        return EagleTokens.bad;
      case 'ALTA':
        return EagleTokens.warn;
      case 'MEDIA':
        return const Color(0xFFF59E0B);
      default:
        return EagleTokens.good;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severidadeColor(ticket.severidade);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    ticket.severidade,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  ticket.criadoEm.length > 10
                      ? ticket.criadoEm.substring(0, 10)
                      : ticket.criadoEm,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.descricao.length > 100
                  ? '${ticket.descricao.substring(0, 100)}…'
                  : ticket.descricao,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (ticket.personalNome != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    ticket.personalNome!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => onResolver(ticket),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Resolver'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Churn Watch ───────────────────────────────────────────────────────

class _ChurnWatchTab extends StatelessWidget {
  final AdminMonitor? monitor;
  final bool loading;
  final void Function(PersonalRisco) onTap;

  const _ChurnWatchTab({
    required this.monitor,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (monitor == null) return const Center(child: Text('Sem dados de monitoramento.'));

    final lista = monitor!.personaisEmRisco;
    if (lista.isEmpty) {
      return const Center(child: Text('Nenhum personal em risco identificado.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (ctx, i) => _RiscoCard(
        personal: lista[i],
        onTap: onTap,
      ),
    );
  }
}

class _RiscoCard extends StatelessWidget {
  final PersonalRisco personal;
  final void Function(PersonalRisco) onTap;
  const _RiscoCard({required this.personal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (personal.alunosInadimplentes > 0) {
      borderColor = EagleTokens.bad;
    } else if (personal.checkInsUltimos30Dias < 5) {
      borderColor = EagleTokens.warn;
    } else {
      borderColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: () => onTap(personal),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: borderColor == Colors.transparent ? 0 : 2),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: borderColor == Colors.transparent
                      ? EagleTokens.good
                      : borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        personal.nome,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        personal.plano,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _InfoBadge(
                            label: '${personal.totalAlunos} alunos',
                            icon: Icons.people_outline,
                            color: const Color(0xFF2B4A9E),
                          ),
                          const SizedBox(width: 8),
                          if (personal.alunosInadimplentes > 0)
                            _InfoBadge(
                              label: '${personal.alunosInadimplentes} inadimp.',
                              icon: Icons.warning_amber_rounded,
                              color: EagleTokens.bad,
                            ),
                          const SizedBox(width: 8),
                          _InfoBadge(
                            label: '${personal.checkInsUltimos30Dias} check-ins',
                            icon: Icons.fitness_center,
                            color: personal.checkInsUltimos30Dias < 5
                                ? EagleTokens.warn
                                : EagleTokens.good,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: EagleTokens.inkMute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Tab 4: Personais ────────────────────────────────────────────────────────

class _PersonaisTab extends StatelessWidget {
  final List<AdminPersonal> personais;
  final Future<void> Function(AdminPersonal) onToggleAdmin;
  const _PersonaisTab({required this.personais, required this.onToggleAdmin});

  @override
  Widget build(BuildContext context) {
    if (personais.isEmpty) {
      return const Center(child: Text('Nenhum personal cadastrado.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${personais.length} personais cadastrados',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            itemCount: personais.length,
            itemBuilder: (_, i) {
              final p = personais[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(p.nome[0].toUpperCase())),
                  title: Text(p.nome),
                  subtitle: Text('${p.email}\nPlano: ${p.plano} • Desde: ${p.criadoEm}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(
                        label: Text(p.plano, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                      ),
                      if (p.isAdmin)
                        const Icon(Icons.admin_panel_settings,
                            color: Color(0xFF7B1FA2), size: 16),
                    ],
                  ),
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(p.isAdmin ? 'Remover admin?' : 'Tornar admin?'),
                        content: Text('${p.nome} (${p.email})'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar')),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Confirmar')),
                        ],
                      ),
                    );
                    if (confirm == true) onToggleAdmin(p);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Utilitários ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 5: Auditoria ────────────────────────────────────────────────────────

class _AuditoriaLog {
  final int id;
  final String acao;
  final String? entidade;
  final String? detalhes;
  final String criadoEm;

  _AuditoriaLog({
    required this.id,
    required this.acao,
    this.entidade,
    this.detalhes,
    required this.criadoEm,
  });

  factory _AuditoriaLog.fromJson(Map<String, dynamic> j) => _AuditoriaLog(
        id: j['id'] as int,
        acao: j['acao'] as String? ?? '',
        entidade: j['entidade'] as String?,
        detalhes: j['detalhes'] as String?,
        criadoEm: j['criadoEm'] as String? ?? '',
      );
}

class _AuditoriaTab extends ConsumerStatefulWidget {
  const _AuditoriaTab();

  @override
  ConsumerState<_AuditoriaTab> createState() => _AuditoriaTabState();
}

class _AuditoriaTabState extends ConsumerState<_AuditoriaTab>
    with AutomaticKeepAliveClientMixin {
  List<_AuditoriaLog> _logs = [];
  bool _loading = true;
  String? _erro;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/api/auditoria?limit=100');
      final list = (res.data as List? ?? [])
          .map((e) => _AuditoriaLog.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _logs = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }

  Color _acaoColor(String acao) {
    if (acao.contains('DELETE') || acao.contains('EXCLUIR')) return EagleTokens.bad;
    if (acao.contains('CREATE') || acao.contains('CRIAR')) return EagleTokens.good;
    if (acao.contains('UPDATE') || acao.contains('EDITAR')) return EagleTokens.warn;
    return EagleTokens.brand;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off, size: 64, color: EagleTokens.inkMute),
            const SizedBox(height: 12),
            Text('Sem dados de auditoria', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: EagleTokens.inkMute)),
            const SizedBox(height: 8),
            Text('Endpoint /api/admin/auditoria não disponível', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: EagleTokens.inkMute)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 64, color: EagleTokens.inkMute),
            const SizedBox(height: 12),
            const Text('Nenhuma ação auditada ainda.', style: TextStyle(color: EagleTokens.inkMute)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final log = _logs[i];
          final cor = _acaoColor(log.acao);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cor.withValues(alpha: 0.12),
                child: Icon(Icons.security, color: cor, size: 20),
              ),
              title: Text(log.acao, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (log.entidade != null)
                    Text('Entidade: ${log.entidade}', style: const TextStyle(fontSize: 12)),
                  if (log.detalhes != null)
                    Text(log.detalhes!, style: const TextStyle(fontSize: 11, color: EagleTokens.inkMute), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(_fmtDate(log.criadoEm), style: const TextStyle(fontSize: 11, color: EagleTokens.inkMute)),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab 6: Feature Flags ────────────────────────────────────────────────────

class _FeatureFlag {
  final String nome;
  final bool ativo;
  final bool temOverride;

  _FeatureFlag({
    required this.nome,
    required this.ativo,
    this.temOverride = false,
  });

  factory _FeatureFlag.fromJson(Map<String, dynamic> j) => _FeatureFlag(
        nome: j['nome'] as String? ?? '',
        ativo: j['ativo'] as bool? ?? false,
        temOverride: j['temOverride'] as bool? ?? false,
      );
}

class _FeatureFlagsTab extends ConsumerStatefulWidget {
  const _FeatureFlagsTab();

  @override
  ConsumerState<_FeatureFlagsTab> createState() => _FeatureFlagsTabState();
}

class _FeatureFlagsTabState extends ConsumerState<_FeatureFlagsTab>
    with AutomaticKeepAliveClientMixin {
  List<_FeatureFlag> _flags = [];
  bool _loading = true;
  String? _erro;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/api/flags');
      final list = (res.data as List? ?? [])
          .map((e) => _FeatureFlag.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _flags = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggle(_FeatureFlag flag) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.put('/api/flags/global/${flag.nome}?ativo=${!flag.ativo}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _criarFlag() async {
    final nomeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nova Feature Flag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome da flag (ex: NOVA_IA)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (nomeCtrl.text.trim().isEmpty) return;
                try {
                  final dio = ref.read(apiClientProvider).dio;
                  await dio.put('/api/flags/global/${nomeCtrl.text.trim().toUpperCase()}?ativo=false');
                  _load();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              },
              child: const Text('Criar Flag'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarFlag,
        icon: const Icon(Icons.add),
        label: const Text('Nova Flag'),
      ),
      body: _erro != null || _flags.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.toggle_off, size: 64, color: const Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  Text(
                    _flags.isEmpty ? 'Nenhuma feature flag cadastrada.' : 'Sem dados disponíveis',
                    style: const TextStyle(color: EagleTokens.inkMute),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Recarregar')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _flags.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final flag = _flags[i];
                  return Card(
                    child: SwitchListTile(
                      secondary: CircleAvatar(
                        backgroundColor: flag.ativo
                            ? EagleTokens.good.withValues(alpha: 0.12)
                            : EagleTokens.inkMute.withValues(alpha: 0.12),
                        child: Icon(
                          flag.ativo ? Icons.toggle_on : Icons.toggle_off,
                          color: flag.ativo ? EagleTokens.good : EagleTokens.inkMute,
                        ),
                      ),
                      title: Text(flag.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                      subtitle: Text(
                        flag.temOverride ? 'Override por tenant ativo' : 'Flag global',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: flag.ativo,
                      onChanged: (_) => _toggle(flag),
                    ),
                  );
                },
              ),
            ),
    );
  }
}


