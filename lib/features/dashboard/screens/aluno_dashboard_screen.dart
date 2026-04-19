import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class AlunoDashboardScreen extends ConsumerWidget {
  const AlunoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Treino'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuButton(
              icon: Icons.fitness_center,
              label: 'Meus Treinos',
              subtitle: 'Ver e executar treinos atribuídos',
              onTap: () => context.push('/checkin/treinos'),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.history,
              label: 'Histórico',
              subtitle: 'Treinos realizados',
              onTap: () => context.push('/checkin/historico'),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.dynamic_feed,
              label: 'Feed',
              subtitle: 'Publicações do seu personal',
              onTap: () => context.push('/feed/aluno'),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat com Personal',
              subtitle: 'Envie mensagens ao seu personal',
              onTap: () => context.push('/chat/aluno'),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.smart_toy,
              label: 'Assistente IA',
              subtitle: 'Tire dúvidas com inteligência artificial',
              onTap: () => context.push('/ia/chat'),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.payments,
              label: 'Financeiro',
              subtitle: 'Veja suas mensalidades e situação financeira',
              onTap: () => context.push('/financeiro/aluno'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
