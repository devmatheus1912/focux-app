import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
          loading: () => const SkeletonList(count: 5),
          error:
              (_, __) => ListView(
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
                        color:
                            isDark
                                ? EagleTokens.darkLine
                                : EagleTokens.lineSoft,
                      ),
                    ),
                    child: Text(
                      'Quando houver PR, mensagem importante ou alerta operacional, tudo aparece aqui.',
                      style: TextStyle(
                        color:
                            isDark
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
                final group = _groupLabel(item.criadaEm);
                final previousGroup =
                    index == 0 ? null : _groupLabel(items[index - 1].criadaEm);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0 || group != previousGroup)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                        child: Text(
                          group.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? EagleTokens.darkInkMute
                                    : EagleTokens.inkMute,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    _NotificationTile(
                      item: item,
                      isDark: isDark,
                      primary: primary,
                      onTap: () async {
                        if (!item.lida) {
                          await repo.marcarLida(item.id);
                          await reload();
                        }
                        final route = item.route;
                        if (route != null &&
                            route.startsWith('/') &&
                            context.mounted) {
                          context.push(route);
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _groupLabel(DateTime? date) {
  if (date == null) return 'Anteriores';
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Hoje';
  if (day == today.subtract(const Duration(days: 1))) return 'Ontem';
  return 'Anteriores';
}

Color _notifColor(String tipo, Color primary) {
  switch (tipo.toLowerCase()) {
    case 'risco':
    case 'alerta':
      return EagleTokens.bad;
    case 'pag':
    case 'pagamento':
      return EagleTokens.good;
    case 'ai':
    case 'ia':
      return EagleTokens.purple;
    case 'feed':
      return EagleTokens.warn;
    default:
      return primary;
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
    final tipoColor = _notifColor(item.tipo, primary);

    return Opacity(
      opacity: item.lida ? 0.75 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.lida ? line : tipoColor.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tipoColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(item.tipo),
                      color: tipoColor,
                      size: 20,
                    ),
                  ),
                  if (!item.lida)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: tipoColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight:
                            item.lida ? FontWeight.w400 : FontWeight.w600,
                      ),
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
                          color: tipoColor,
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
