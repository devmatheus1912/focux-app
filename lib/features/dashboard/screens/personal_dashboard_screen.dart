import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class PersonalDashboardScreen extends ConsumerWidget {
  const PersonalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (data) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Plano: ${data.planoAtual}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total de Alunos',
                      value: data.totalAlunos.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Alunos Ativos',
                      value: data.alunosAtivos.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'Limite do Plano',
                value: '${data.alunosAtivos} / ${data.limiteAlunos}',
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('Menu', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              _MenuButton(
                icon: Icons.people,
                label: 'Meus Alunos',
                onTap: () => context.push('/alunos'),
              ),
              _MenuButton(
                icon: Icons.person_add,
                label: 'Convidar Aluno',
                onTap: () => context.push('/convites'),
              ),
              _MenuButton(
                icon: Icons.person,
                label: 'Meu Perfil',
                onTap: () => context.push('/perfil'),
              ),
              _MenuButton(
                icon: Icons.workspace_premium,
                label: 'Planos e Assinatura',
                onTap: () => context.push('/planos'),
              ),
              _MenuButton(
                icon: Icons.fitness_center,
                label: 'Exercícios',
                onTap: () => context.push('/exercicios'),
              ),
              _MenuButton(
                icon: Icons.list_alt,
                label: 'Treinos',
                onTap: () => context.push('/treinos'),
              ),
              _MenuButton(
                icon: Icons.attach_money,
                label: 'Financeiro',
                onTap: () => context.push('/financeiro'),
              ),
              _MenuButton(
                icon: Icons.calendar_month,
                label: 'Agenda',
                onTap: () => context.push('/agenda'),
              ),
              _MenuButton(
                icon: Icons.dynamic_feed,
                label: 'Feed de Conteúdo',
                onTap: () => context.push('/feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
