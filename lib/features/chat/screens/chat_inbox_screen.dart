import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';

final chatInboxProvider = FutureProvider<List<ChatInboxItem>>((ref) async {
  return ChatRepository(ref.read(apiClientProvider)).inbox();
});

final chatInboxUnreadProvider = FutureProvider<List<ChatInboxItem>>((
  ref,
) async {
  return ChatRepository(ref.read(apiClientProvider)).inboxUnread();
});

final chatInboxArchivedProvider = FutureProvider<List<ChatInboxItem>>((
  ref,
) async {
  return ChatRepository(ref.read(apiClientProvider)).inboxArchived();
});

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<ChatMsg>? _searchResults;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    try {
      final results = await ChatRepository(
        ref.read(apiClientProvider),
      ).globalSearch(query.trim());
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {}
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchCtrl.clear();
        _searchResults = null;
      }
    });
  }

  Future<void> _conversationAction(int alunoId, String action) async {
    HapticFeedback.mediumImpact();
    try {
      await ChatRepository(
        ref.read(apiClientProvider),
      ).conversationAction(alunoId, action);
      ref.invalidate(chatInboxProvider);
      ref.invalidate(chatInboxUnreadProvider);
      ref.invalidate(chatInboxArchivedProvider);
      if (mounted) {
        final labels = {
          'pin': 'Fixada',
          'unpin': 'Desafixada',
          'archive': 'Arquivada',
          'unarchive': 'Desarquivada',
          'mute': 'Silenciada',
          'unmute': 'Notificações ativadas',
          'clear': 'Conversa limpa',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(labels[action] ?? 'Ação aplicada'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao executar ação'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ink),
          onPressed: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        title:
            _isSearching
                ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: TextStyle(color: ink, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Buscar em todas as conversas...',
                    hintStyle: TextStyle(color: mute),
                    border: InputBorder.none,
                  ),
                  onChanged: _performSearch,
                )
                : const Text('Mensagens'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: ink),
            onPressed: _toggleSearch,
          ),
        ],
        bottom:
            _isSearching
                ? null
                : TabBar(
                  controller: _tabCtrl,
                  labelColor: primary,
                  unselectedLabelColor: mute,
                  indicatorColor: primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Todas'),
                    Tab(text: 'Não lidas'),
                    Tab(text: 'Arquivadas'),
                  ],
                ),
      ),
      body:
          _isSearching && _searchResults != null
              ? _buildSearchResults(isDark, primary, ink, mute)
              : _isSearching
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 48, color: mute),
                    const SizedBox(height: 12),
                    Text(
                      'Digite para buscar...',
                      style: TextStyle(color: mute),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildInboxTab(
                    ref.watch(chatInboxProvider),
                    chatInboxProvider,
                    isDark,
                    primary,
                    ink,
                    mute,
                  ),
                  _buildInboxTab(
                    ref.watch(chatInboxUnreadProvider),
                    chatInboxUnreadProvider,
                    isDark,
                    primary,
                    ink,
                    mute,
                    emptyMsg: 'Nenhuma mensagem não lida',
                  ),
                  _buildInboxTab(
                    ref.watch(chatInboxArchivedProvider),
                    chatInboxArchivedProvider,
                    isDark,
                    primary,
                    ink,
                    mute,
                    emptyMsg: 'Nenhuma conversa arquivada',
                    isArchived: true,
                  ),
                ],
              ),
    );
  }

  Widget _buildSearchResults(
    bool isDark,
    Color primary,
    Color ink,
    Color mute,
  ) {
    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: mute),
            const SizedBox(height: 12),
            Text('Nenhum resultado encontrado', style: TextStyle(color: mute)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      itemCount: _searchResults!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final msg = _searchResults![index];
        return _SearchResultTile(
          msg: msg,
          isDark: isDark,
          ink: ink,
          mute: mute,
        );
      },
    );
  }

  Widget _buildInboxTab(
    AsyncValue<List<ChatInboxItem>> async,
    FutureProvider<List<ChatInboxItem>> provider,
    bool isDark,
    Color primary,
    Color ink,
    Color mute, {
    String emptyMsg = 'Nenhuma conversa ainda',
    bool isArchived = false,
  }) {
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: primary)),
      error:
          (e, _) => _InboxState(
            icon: Icons.wifi_off_rounded,
            title: 'Não foi possível carregar',
            message: 'Toque para tentar novamente.',
            color: mute,
            onTap: () => ref.invalidate(provider),
          ),
      data: (items) {
        if (items.isEmpty) {
          return _InboxState(
            icon:
                isArchived ? Icons.archive_outlined : Icons.chat_bubble_outline,
            title: emptyMsg,
            message:
                isArchived
                    ? 'Arraste conversas para a esquerda para arquivar.'
                    : 'Abra o perfil de um aluno para iniciar o primeiro chat.',
            color: mute,
          );
        }
        return RefreshIndicator(
          color: primary,
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder:
                (context, index) => Dismissible(
                  key: Key('inbox-${items[index].alunoId}'),
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      // Swipe left → archive/unarchive
                      await _conversationAction(
                        items[index].alunoId,
                        isArchived ? 'unarchive' : 'archive',
                      );
                      return false;
                    } else {
                      // Swipe right → pin/unpin
                      await _conversationAction(items[index].alunoId, 'pin');
                      return false;
                    }
                  },
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.push_pin, color: primary),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: EagleTokens.warn.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isArchived ? Icons.unarchive : Icons.archive,
                      color: EagleTokens.warn,
                    ),
                  ),
                  child: _InboxTile(
                    item: items[index],
                    isDark: isDark,
                    onTap:
                        () => context.push(
                          '/alunos/${items[index].alunoId}/chat',
                          extra: items[index].alunoNome,
                        ),
                    onLongPress: () => _showConversationActions(items[index]),
                  ),
                ),
          ),
        );
      },
    );
  }

  void _showConversationActions(ChatInboxItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.alunoNome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                  ),
                ),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.push_pin,
                  label: 'Fixar conversa',
                  onTap: () {
                    Navigator.pop(ctx);
                    _conversationAction(item.alunoId, 'pin');
                  },
                ),
                _ActionTile(
                  icon: Icons.archive_outlined,
                  label: 'Arquivar',
                  onTap: () {
                    Navigator.pop(ctx);
                    _conversationAction(item.alunoId, 'archive');
                  },
                ),
                _ActionTile(
                  icon: Icons.notifications_off_outlined,
                  label: 'Silenciar',
                  onTap: () {
                    Navigator.pop(ctx);
                    _conversationAction(item.alunoId, 'mute');
                  },
                ),
                _ActionTile(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Limpar conversa',
                  color: EagleTokens.bad,
                  onTap: () {
                    Navigator.pop(ctx);
                    _conversationAction(item.alunoId, 'clear');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? EagleTokens.darkInk : EagleTokens.ink);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ChatMsg msg;
  final bool isDark;
  final Color ink;
  final Color mute;
  const _SearchResultTile({
    required this.msg,
    required this.isDark,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (msg.alunoId != null) {
          context.push('/alunos/${msg.alunoId}/chat');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCard : EagleTokens.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  msg.remetente == 'PERSONAL' ? Icons.person : Icons.school,
                  size: 14,
                  color: mute,
                ),
                const SizedBox(width: 6),
                Text(
                  msg.remetente == 'PERSONAL' ? 'Você' : 'Aluno',
                  style: TextStyle(
                    fontSize: 11,
                    color: mute,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  fxTimeAgo(msg.enviadoEm),
                  style: TextStyle(fontSize: 11, color: mute),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.conteudo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: ink),
            ),
          ],
        ),
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
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: color),
              ),
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
  final VoidCallback? onLongPress;

  const _InboxTile({
    required this.item,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brandSoft = BrandPalette.soft(primary, dark: isDark);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            // Avatar
            item.fotoUrl != null && item.fotoUrl!.isNotEmpty
                ? CircleAvatar(
                  backgroundImage: NetworkImage(item.fotoUrl!),
                  radius: 24,
                )
                : CircleAvatar(
                  radius: 24,
                  backgroundColor: brandSoft,
                  child: Text(
                    fxInitials(item.alunoNome),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.alunoNome,
                          style: TextStyle(
                            color: ink,
                            fontWeight:
                                item.naoLidas > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        fxTimeAgo(item.enviadoEm),
                        style: TextStyle(
                          color: item.naoLidas > 0 ? primary : mute,
                          fontSize: 11,
                          fontWeight:
                              item.naoLidas > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.ultimoRemetente == 'PERSONAL')
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all, size: 14, color: mute),
                        ),
                      Expanded(
                        child: Text(
                          item.ultimaMensagem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.naoLidas > 0 ? ink : mute,
                            fontSize: 13,
                            fontWeight:
                                item.naoLidas > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (item.naoLidas > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.naoLidas > 99
                                ? '99+'
                                : item.naoLidas.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
