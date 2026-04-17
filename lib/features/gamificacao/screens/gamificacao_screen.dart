import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/gamificacao_repository.dart';

final _gamificacaoRepoProvider = Provider<GamificacaoRepository>(
  (ref) => GamificacaoRepository(ref.read(apiClientProvider)),
);

final gamificacaoProvider = FutureProvider.autoDispose<GamificacaoData>((ref) {
  return ref.read(_gamificacaoRepoProvider).getGamificacao();
});

final referralProvider = FutureProvider.autoDispose<ReferralCupom>((ref) {
  return ref.read(_gamificacaoRepoProvider).getReferral();
});

class GamificacaoScreen extends ConsumerWidget {
  const GamificacaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificacaoAsync = ref.watch(gamificacaoProvider);
    final referralAsync = ref.watch(referralProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Evolução'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamificacaoProvider);
          ref.invalidate(referralProvider);
        },
        child: gamificacaoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Erro ao carregar dados: $e'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(gamificacaoProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          data: (dados) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StreakCard(streak: dados.streak, totalTreinos: dados.totalTreinos),
              const SizedBox(height: 16),
              _BadgesSection(badges: dados.badges),
              const SizedBox(height: 16),
              referralAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox.shrink(),
                data: (cupom) => _ReferralCard(cupom: cupom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final Streak streak;
  final int totalTreinos;

  const _StreakCard({required this.streak, required this.totalTreinos});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${streak.streakAtual} dias seguidos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Recorde: ${streak.streakMaximo} dias',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icone: Icons.fitness_center,
                  valor: '$totalTreinos',
                  rotulo: 'Treinos concluídos',
                ),
                _StatItem(
                  icone: Icons.emoji_events,
                  valor: '${streak.streakMaximo}',
                  rotulo: 'Melhor sequência',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String rotulo;

  const _StatItem({
    required this.icone,
    required this.valor,
    required this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icone, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          valor,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          rotulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BadgesSection extends StatelessWidget {
  final List<Badge> badges;

  const _BadgesSection({required this.badges});

  IconData _iconeParaTipo(String tipo) {
    switch (tipo) {
      case 'STREAK_10':
        return Icons.local_fire_department;
      case 'PR_CARGA':
        return Icons.fitness_center;
      case 'FREQUENCIA_100':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  Color _corParaTipo(String tipo) {
    switch (tipo) {
      case 'STREAK_10':
        return Colors.orange;
      case 'PR_CARGA':
        return Colors.blue;
      case 'FREQUENCIA_100':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conquistas',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (badges.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 40, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma conquista ainda.\nConclua treinos para ganhar badges!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, i) => _BadgeCard(
              badge: badges[i],
              icone: _iconeParaTipo(badges[i].tipo),
              cor: _corParaTipo(badges[i].tipo),
            ),
          ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final IconData icone;
  final Color cor;

  const _BadgeCard({
    required this.badge,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: cor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              badge.descricao,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final ReferralCupom cupom;

  const _ReferralCard({required this.cupom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Indique um amigo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Seu amigo ganha ${cupom.descontoPercentual}% de desconto!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cupom.codigo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    color: theme.colorScheme.onPrimaryContainer,
                    tooltip: 'Copiar código',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cupom.codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (cupom.foiUsado) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Cupom já utilizado',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
                onPressed: () {
                  final texto =
                      'Use meu código ${cupom.codigo} e ganhe ${cupom.descontoPercentual}% de desconto no Focux!';
                  Clipboard.setData(ClipboardData(text: texto));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensagem copiada para compartilhar!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
