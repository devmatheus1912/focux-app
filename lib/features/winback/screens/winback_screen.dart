import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Win-back automático roda no backend (FCM). Sem endpoint de listagem ainda.
class WinbackScreen extends StatelessWidget {
  const WinbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      appBar: FxShellAppBar(
        title: 'Win-back automático',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications_active_outlined, color: primary, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Automação FCM ativa',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O Focux envia push de reengajamento para alunos inativos e lembretes de trial. '
                    'Os envios são registrados no servidor; em breve você verá o histórico aqui.',
                    style: TextStyle(
                      height: 1.45,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/retencao'),
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: const Text('Ver saúde da base'),
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
