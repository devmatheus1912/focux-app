import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'progresso_semanal_widget.dart';

class AlunoDashboardScreen extends ConsumerWidget {
  const AlunoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        title: Text('Meu Treino', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
            onPressed: () {
              final currentMode = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProgressoSemanalWidget(),
            const SizedBox(height: 24),
            Text('Meus Atalhos', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _MenuButton(icon: Icons.fitness_center, label: 'Meus Treinos', subtitle: 'Ver e executar treinos atribuídos', onTap: () => context.push('/checkin/treinos'), isDark: isDark),
            const SizedBox(height: 10),
            _MenuButton(icon: Icons.history, label: 'Histórico', subtitle: 'Treinos realizados', onTap: () => context.push('/checkin/historico'), isDark: isDark),
            const SizedBox(height: 10),
            _MenuButton(icon: Icons.dynamic_feed, label: 'Feed', subtitle: 'Publicações do seu personal', onTap: () => context.push('/feed/aluno'), isDark: isDark),
            const SizedBox(height: 10),
            _MenuButton(icon: Icons.chat_bubble_outline, label: 'Chat com Personal', subtitle: 'Envie mensagens ao seu personal', onTap: () => context.push('/chat/aluno'), isDark: isDark),
            const SizedBox(height: 10),
            _MenuButton(icon: Icons.smart_toy, label: 'Assistente IA', subtitle: 'Tire dúvidas com inteligência artificial', onTap: () => context.push('/ia/chat'), isDark: isDark),
            const SizedBox(height: 10),
            _MenuButton(icon: Icons.payments, label: 'Financeiro', subtitle: 'Veja suas mensalidades', onTap: () => context.push('/financeiro/aluno'), isDark: isDark),
            const SizedBox(height: 10),
            _MenuButton(icon: Icons.calendar_month, label: 'Minha Agenda', subtitle: 'Veja e confirme seus agendamentos', onTap: () => context.push('/agenda/aluno'), isDark: isDark),
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
  final bool isDark;

  const _MenuButton({required this.icon, required this.label, required this.subtitle, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: EagleTokens.brand, size: 22),
        ),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? EagleTokens.darkInk : EagleTokens.ink)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
        onTap: onTap,
      ),
    );
  }
}
