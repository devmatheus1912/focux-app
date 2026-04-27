import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';

final chatInboxProvider = FutureProvider<List<ChatInboxItem>>((ref) async {
  return ChatRepository(ref.read(apiClientProvider)).inbox();
});

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatInboxProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: ink,
        title: const Text('Mensagens'),
      ),
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: primary)),
        error: (e, _) => _InboxState(
          icon: Icons.wifi_off_rounded,
          title: 'Nao foi possivel carregar',
          message: 'Toque para tentar novamente.',
          color: mute,
          onTap: () => ref.invalidate(chatInboxProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _InboxState(
              icon: Icons.chat_bubble_outline,
              title: 'Nenhuma conversa ainda',
              message: 'Abra o perfil de um aluno para iniciar o primeiro chat.',
              color: mute,
            );
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () async => ref.invalidate(chatInboxProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _InboxTile(
                item: items[index],
                isDark: isDark,
                onTap: () => context.push(
                  '/alunos/${items[index].alunoId}/chat',
                  extra: items[index].alunoNome,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InboxState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final VoidCallback? onTap;

  const _InboxState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final ChatInboxItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _InboxTile({required this.item, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final prefix = item.ultimoRemetente == 'PERSONAL' ? 'Voce: ' : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primarySoft,
              backgroundImage: item.fotoUrl == null || item.fotoUrl!.isEmpty
                  ? null
                  : NetworkImage(item.fotoUrl!),
              child: item.fotoUrl == null || item.fotoUrl!.isEmpty
                  ? Text(
                      fxInitials(item.alunoNome),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.alunoNome, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Text(_formatTime(item.enviadoEm), style: TextStyle(color: mute, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$prefix${item.ultimaMensagem}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: mute, fontSize: 13)),
                ],
              ),
            ),
            if (item.naoLidas > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                child: Text('${item.naoLidas}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.difference(local).inDays == 0) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}
