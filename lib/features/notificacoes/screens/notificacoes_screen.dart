import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/notificacoes_repository.dart';

class NotificacoesScreen extends ConsumerWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(notificacoesProvider);
    final repo = ref.read(notificacoesRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;

    Future<void> reload() async {
      ref.invalidate(notificacoesProvider);
      ref.invalidate(notificacoesNaoLidasProvider);
    }

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        title: const Text('Notificacoes'),
        actions: [
          TextButton(
            onPressed: () async {
              await repo.marcarTodasLidas();
              await reload();
            },
            child: const Text('Ler todas'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reload,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              Text('Nao foi possivel carregar suas notificacoes agora.'),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? EagleTokens.darkLine
                            : EagleTokens.lineSoft,
                      ),
                    ),
                    child: Text(
                      'Quando houver PR, mensagem importante ou alerta operacional, tudo aparece aqui.',
                      style: TextStyle(
                        color: isDark
                            ? EagleTokens.darkInkMute
                            : EagleTokens.inkMute,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationTile(
                  item: item,
                  isDark: isDark,
                  primary: primary,
                  onTap: () async {
                    if (!item.lida) {
                      await repo.marcarLida(item.id);
                      await reload();
                    }
                    final route = item.route;
                    if (route != null && route.startsWith('/') && context.mounted) {
                      context.push(route);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificacaoApp item;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.lida ? line : primary.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: BrandPalette.soft(primary, dark: isDark),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(item.tipo), color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight:
                                item.lida ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!item.lida)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.mensagem,
                    style: TextStyle(color: mute, height: 1.4),
                  ),
                  if (item.ctaLabel != null && item.ctaLabel!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.ctaLabel!,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String tipo) {
    switch (tipo) {
      case 'EVOLUCAO':
        return Icons.trending_up_rounded;
      case 'ALERTA':
        return Icons.priority_high_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
