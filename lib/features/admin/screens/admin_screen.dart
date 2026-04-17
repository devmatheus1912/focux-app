import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/admin_repository.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  AdminStats? _stats;
  List<AdminPersonal> _personais = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
      setState(() {
        _stats = results[0] as AdminStats;
        _personais = results[1] as List<AdminPersonal>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin(AdminPersonal p) async {
    try {
      await AdminRepository(ref.read(apiClientProvider)).toggleAdmin(p.id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Painel Admin'),
      bottom: TabBar(controller: _tabs, tabs: const [
        Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
        Tab(icon: Icon(Icons.people), text: 'Personais'),
      ]),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabs, children: [
            _StatsTab(stats: _stats),
            _PersonaisTab(personais: _personais, onToggleAdmin: _toggleAdmin),
          ]),
  );
}

class _StatsTab extends StatelessWidget {
  final AdminStats? stats;
  const _StatsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const Center(child: Text('Sem dados'));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 8),
        Text('Plataforma Focux', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _StatCard(label: 'Personais', value: '${stats!.totalPersonais}', icon: Icons.fitness_center, color: Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Alunos', value: '${stats!.totalAlunos}', icon: Icons.people, color: Colors.green)),
        ]),
        const SizedBox(height: 12),
        _StatCard(label: 'Admins', value: '${stats!.admins}', icon: Icons.admin_panel_settings, color: Colors.purple),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ]),
    ),
  );
}

class _PersonaisTab extends StatelessWidget {
  final List<AdminPersonal> personais;
  final Future<void> Function(AdminPersonal) onToggleAdmin;
  const _PersonaisTab({required this.personais, required this.onToggleAdmin});

  @override
  Widget build(BuildContext context) {
    if (personais.isEmpty) return const Center(child: Text('Nenhum personal cadastrado.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
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
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Chip(
                label: Text(p.plano, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
              ),
              if (p.isAdmin)
                const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 16),
            ]),
            onLongPress: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(p.isAdmin ? 'Remover admin?' : 'Tornar admin?'),
                  content: Text('${p.nome} (${p.email})'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
                  ],
                ),
              );
              if (confirm == true) onToggleAdmin(p);
            },
          ),
        );
      },
    );
  }
}
