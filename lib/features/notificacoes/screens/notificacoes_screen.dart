import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_icon.dart';
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
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    Future<void> reload() async {
      ref.invalidate(notificacoesProvider);
      ref.invalidate(notificacoesNaoLidasProvider);
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Notificações',
          style: TextStyle(color: ink, fontWeight: FontWeight.w900),
        ),
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
          loading:
              () => ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: const [SkeletonList(count: 5)],
              ),
          error:
              (_, __) => _NotificationsStateCard(
                isDark: isDark,
                primary: primary,
                icon: 'bell',
                title: 'Não foi possível carregar',
                subtitle: 'Puxe para atualizar ou tente novamente.',
              ),
          data: (items) {
            if (items.isEmpty) {
              return _NotificationsStateCard(
                isDark: isDark,
                primary: primary,
                icon: 'circle-check',
                title: 'Tudo em ordem',
                subtitle:
                    'Alertas operacionais, mensagens importantes e Radar Focux aparecem aqui.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                        padding: const EdgeInsets.fromLTRB(2, 8, 0, 8),
                        child: Text(
                          group.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color:
                                isDark
                                    ? EagleTokens.darkInkMute
                                    : EagleTokens.inkMute,
                            letterSpacing: 0.9,
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
    case 'radar':
      return primary;
    case 'feed':
      return EagleTokens.warn;
    default:
      return primary;
  }
}

String _humanTitle(NotificacaoApp item) {
  final title = item.titulo.trim();
  final msg = item.mensagem.trim();
  if (title.toLowerCase().startsWith('radar focux:')) {
    final name = title.split(':').skip(1).join(':').trim();
    return name.isEmpty ? 'Aluno precisa de ação' : '$name precisa de ação';
  }
  if (title.isNotEmpty) return title;
  if (msg.isNotEmpty) return msg;
  return 'Nova notificação';
}

String _badgeLabel(NotificacaoApp item) {
  final title = item.titulo.toLowerCase();
  if (title.contains('radar focux') || item.tipo.toLowerCase() == 'radar') {
    return 'Radar Focux';
  }
  switch (item.tipo.toLowerCase()) {
    case 'risco':
    case 'alerta':
      return 'Alerta';
    case 'pag':
    case 'pagamento':
      return 'Financeiro';
    case 'ia':
    case 'ai':
      return 'IA';
    default:
      return item.tipo.isEmpty ? 'Info' : item.tipo;
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
    final unread = !item.lida;
    final action =
        item.ctaLabel?.trim().isNotEmpty == true
            ? item.ctaLabel!.trim()
            : item.route?.startsWith('/') == true
            ? 'Abrir'
            : null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: item.lida ? 0.76 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread ? tipoColor.withValues(alpha: 0.22) : line,
            ),
            boxShadow: [
              if (!isDark && unread)
                BoxShadow(
                  color: const Color(0xFF0B1220).withValues(alpha: 0.035),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tipoColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _iconFor(item.tipo, item.titulo),
                      color: tipoColor,
                      size: 18,
                    ),
                  ),
                  if (unread)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: tipoColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _humanTitle(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TinyBadge(
                          label: _badgeLabel(item),
                          color: tipoColor,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.mensagem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.1,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        action,
                        style: TextStyle(
                          color: tipoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
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

  IconData _iconFor(String tipo, String titulo) {
    final lowTipo = tipo.toLowerCase();
    final lowTitle = titulo.toLowerCase();
    if (lowTitle.contains('radar')) return Icons.radar_outlined;
    switch (lowTipo) {
      case 'evolucao':
        return Icons.trending_up_rounded;
      case 'alerta':
      case 'risco':
        return Icons.priority_high_rounded;
      case 'pagamento':
      case 'pag':
        return Icons.attach_money_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotificationsStateCard extends StatelessWidget {
  const _NotificationsStateCard({
    required this.isDark,
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool isDark;
  final Color primary;
  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: FxIcon(name: icon, color: primary)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle, style: TextStyle(color: mute, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
