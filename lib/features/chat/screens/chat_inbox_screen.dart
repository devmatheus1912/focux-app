import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/alunos/data/aluno_repository.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

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
  final Set<int> _selectedAlunoIds = <int>{};

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
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      _selectedAlunoIds.clear();
      if (!_isSearching) {
        _searchCtrl.clear();
        _searchResults = null;
      }
    });
  }

  bool get _selectionActive => _selectedAlunoIds.isNotEmpty;

  void _toggleSelection(int alunoId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedAlunoIds.contains(alunoId)) {
        _selectedAlunoIds.remove(alunoId);
      } else {
        _selectedAlunoIds.add(alunoId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedAlunoIds.clear());
  }

  Future<void> _deleteSelectedConversations() async {
    final ids = _selectedAlunoIds.toList();
    if (ids.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        return AlertDialog(
          title: Text(
            ids.length == 1 ? 'Excluir mensagens?' : 'Excluir conversas?',
            style: TextStyle(color: ink),
          ),
          content: Text(
            ids.length == 1
                ? 'As mensagens desta conversa serao limpas da sua caixa.'
                : 'As mensagens das ${ids.length} conversas selecionadas serao limpas da sua caixa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      for (final alunoId in ids) {
        await repo.conversationAction(alunoId, 'clear');
      }
      _clearSelection();
      ref.invalidate(chatInboxProvider);
      ref.invalidate(chatInboxUnreadProvider);
      ref.invalidate(chatInboxArchivedProvider);
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: Text(
            ids.length == 1 ? 'Mensagens excluidas' : 'Conversas excluidas',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
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
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(
            content: Text(labels[action] ?? 'Ação aplicada'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;

    return FxShellScaffold(
      useMesh: true,
      floatingActionButton:
          _isSearching || _selectionActive
              ? null
              : FloatingActionButton(
                tooltip: 'Nova mensagem',
                onPressed: _showAlunoPicker,
                child: const Icon(Icons.edit_outlined),
              ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          _isSearching || _selectionActive ? 56 : 104,
        ),
        child:
            _selectionActive || _isSearching
                ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  foregroundColor: ink,
                  automaticallyImplyLeading: !_selectionActive,
                  leading:
                      _selectionActive
                          ? IconButton(
                            icon: Icon(Icons.close_rounded, color: ink),
                            onPressed: _clearSelection,
                          )
                          : IconButton(
                            onPressed: () => safePopOrGo(context, '/dashboard/personal'),
                            icon: Container(
                              width: 38,
                              height: 38,
                              decoration: chrome.headerAction(radius: 12),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: ink,
                              ),
                            ),
                          ),
                  title:
                      _selectionActive
                          ? Text(
                            _selectedAlunoIds.isEmpty
                                ? 'Selecione mensagens'
                                : '${_selectedAlunoIds.length} selecionada(s)',
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                          : TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: TextStyle(color: ink, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Buscar em todas as conversas...',
                              hintStyle: TextStyle(color: mute),
                              border: InputBorder.none,
                            ),
                            onChanged: _performSearch,
                          ),
                  actions: [
                    if (_selectionActive)
                      IconButton(
                        tooltip: 'Excluir mensagens',
                        icon: const Icon(Icons.delete_outline_rounded),
                        color:
                            _selectedAlunoIds.isEmpty
                                ? mute.withValues(alpha: 0.45)
                                : EagleTokens.bad,
                        onPressed:
                            _selectedAlunoIds.isEmpty
                                ? null
                                : _deleteSelectedConversations,
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.close, color: ink),
                        onPressed: _toggleSearch,
                      ),
                  ],
                )
                : Column(
                  children: [
                    FxShellAppBar(
                      title: 'Mensagens',
                      onBack: () => safePopOrGo(context, '/dashboard/personal'),
                      actions: [
                        IconButton(
                          icon: Icon(Icons.search_rounded, color: ink),
                          onPressed: _toggleSearch,
                        ),
                      ],
                    ),
                    TabBar(
                      controller: _tabCtrl,
                      labelColor: primary,
                      unselectedLabelColor: mute,
                      indicatorColor: primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Todas'),
                        Tab(text: 'Não lidas'),
                        Tab(text: 'Arquivadas'),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 110),
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

  void _showAlunoPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: ShellSurface(
              radius: 28,
              child: _AlunoPickerSheet(
                onSelect: (aluno) {
                  Navigator.pop(ctx);
                  context.push('/alunos/${aluno.id}/chat', extra: aluno.nome);
                },
              ),
            ),
          ),
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
      loading: () => Center(child: FxLoading(color: primary)),
      error:
          (e, _) => _InboxState(
            icon: Icons.wifi_off_rounded,
            title: 'Não foi possível carregar',
            message: friendlyError(e),
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
                    : 'Toque no botao de escrever para escolher um aluno.',
            color: mute,
          );
        }
        return RefreshIndicator(
          color: primary,
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 110),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = _selectedAlunoIds.contains(item.alunoId);
              return FxStaggerItem(
                index: index,
                child: Dismissible(
                key: Key('inbox-${item.alunoId}'),
                direction:
                    _selectionActive
                        ? DismissDirection.none
                        : DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    // Swipe left → archive/unarchive
                    await _conversationAction(
                      item.alunoId,
                      isArchived ? 'unarchive' : 'archive',
                    );
                    return false;
                  } else {
                    // Swipe right → pin/unpin
                    await _conversationAction(item.alunoId, 'pin');
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
                  item: item,
                  isDark: isDark,
                  selected: selected,
                  selecting: _selectionActive,
                  onTap: () {
                    if (_selectionActive) {
                      _toggleSelection(item.alunoId);
                      return;
                    }
                    context.push(
                      '/alunos/${item.alunoId}/chat',
                      extra: item.alunoNome,
                    );
                  },
                  onLongPress: () => _toggleSelection(item.alunoId),
                ),
              ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AlunoPickerSheet extends ConsumerStatefulWidget {
  const _AlunoPickerSheet({required this.onSelect});

  final ValueChanged<Aluno> onSelect;

  @override
  ConsumerState<_AlunoPickerSheet> createState() => _AlunoPickerSheetState();
}

class _AlunoPickerSheetState extends ConsumerState<_AlunoPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final async = ref.watch(alunosProvider);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 12, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nova mensagem',
                        style: TextStyle(
                          color: ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: mute),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Buscar aluno',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: chrome.cardFill,
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: chrome.line),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: async.when(
                    loading: () => Center(child: FxLoading(color: primary)),
                    error:
                        (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(TokensStrip.s5),
                            child: Text(
                              friendlyError(e),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: mute),
                            ),
                          ),
                        ),
                    data: (alunos) {
                      final q = _query.toLowerCase();
                      final filtered =
                          q.isEmpty
                              ? alunos
                              : alunos
                                  .where(
                                    (a) =>
                                        a.nome.toLowerCase().contains(q) ||
                                        a.email.toLowerCase().contains(q),
                                  )
                                  .toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum aluno encontrado',
                            style: TextStyle(color: mute),
                          ),
                        );
                      }
                      return ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final aluno = filtered[index];
                          return _AlunoContactTile(
                            aluno: aluno,
                            isDark: isDark,
                            primary: primary,
                            onTap: () => widget.onSelect(aluno),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlunoContactTile extends StatelessWidget {
  const _AlunoContactTile({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.soft(primary, dark: Theme.of(context).brightness == Brightness.dark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: fxListCardDecoration(context),
        child: Row(
          children: [
            aluno.fotoUrl != null && aluno.fotoUrl!.isNotEmpty
                ? CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(aluno.fotoUrl!),
                )
                : CircleAvatar(
                  radius: 22,
                  backgroundColor: soft,
                  child: Text(
                    fxInitials(aluno.nome),
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aluno.email.isNotEmpty ? aluno.email : 'Aluno',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mute, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline_rounded, color: primary, size: 20),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      onTap: () {
        if (msg.alunoId != null) {
          context.push('/alunos/${msg.alunoId}/chat');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: fxListCardDecoration(context),
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
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final card = ShellSurface(
      radius: 18,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: mute),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 12),
            Text(
              'Toque para tentar novamente',
              style: TextStyle(color: mute, fontSize: 12),
            ),
          ],
        ],
      ),
    );
    return Center(child: card);
  }
}

class _InboxTile extends StatelessWidget {
  final ChatInboxItem item;
  final bool isDark;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _InboxTile({
    required this.item,
    required this.isDark,
    this.selected = false,
    this.selecting = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final brandSoft = BrandPalette.soft(primary, dark: Theme.of(context).brightness == Brightness.dark);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration:
            selected
                ? fxListCardDecoration(
                  context,
                  accent: primary,
                  selected: true,
                )
                : fxListCardDecoration(context),
        child: Row(
          children: [
            if (selecting) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? primary : mute.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child:
                    selected
                        ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                        : null,
              ),
              const SizedBox(width: 10),
            ],
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
