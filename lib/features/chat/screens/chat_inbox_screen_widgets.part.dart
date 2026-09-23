part of 'chat_inbox_screen.dart';

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
    final homeAsync = ref.watch(alunosHomeProvider);
    final alunos = alunoPickerAlunosFromHome(homeAsync);
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      expand: true,
      child: Column(
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Nova conversa',
            leading: Icon(
              Icons.chat_bubble_outline_rounded,
              color: primary,
              size: 18,
            ),
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
            child: _buildAlunosBody(
              homeAsync: homeAsync,
              alunos: alunos,
              isDark: isDark,
              primary: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlunosBody({
    required AsyncValue<AlunosHomeBundle> homeAsync,
    required List<Aluno>? alunos,
    required bool isDark,
    required Color primary,
  }) {
    if (alunos != null) {
      final filtered = filterAlunoPickerAlunos(alunos, _query);
      if (filtered.isEmpty) {
        return FxEmptyState(
          icon: _query.isEmpty ? 'users' : 'search',
          title:
              _query.isEmpty
                  ? 'Nenhum aluno cadastrado'
                  : 'Nenhum aluno encontrado',
          subtitle:
              _query.isEmpty
                  ? 'Cadastre um aluno para poder conversar por aqui.'
                  : 'Tente outro nome ou e-mail.',
          quiet: true,
        );
      }
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          FxSettingsGroup(
            children: [
              for (var i = 0; i < filtered.length; i++)
                _AlunoContactTile(
                  aluno: filtered[i],
                  isDark: isDark,
                  primary: primary,
                  showDivider: i < filtered.length - 1,
                  onTap: () => widget.onSelect(filtered[i]),
                ),
            ],
          ),
        ],
      );
    }
    if (homeAsync.hasError) {
      return FxErrorState(
        chromeOnDark: isDark,
        primary: primary,
        message: friendlyError(homeAsync.error ?? 'Erro ao carregar alunos'),
        onRetry: () => ref.invalidate(alunosHomeProvider),
      );
    }
    return const SkeletonList(count: 6);
  }
}

class _AlunoContactTile extends StatelessWidget {
  const _AlunoContactTile({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onTap,
    this.showDivider = true,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    assert(isDark || !isDark);
    return FxSettingsTile(
      fxIcon: 'chat',
      label: aluno.nome,
      subtitle: aluno.email.isNotEmpty ? aluno.email : 'Aluno',
      value: 'Abrir',
      showDivider: showDivider,
      accent: primary,
      accessory: AlunoAvatar(
        name: aluno.nome,
        photoUrl: aluno.fotoUrl,
        variant: AlunoAvatarVariant.strip,
      ),
      onTap: onTap,
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ChatMsg msg;
  final String? alunoNome;
  final bool isDark;
  final Color ink;
  final Color mute;
  const _SearchResultTile({
    required this.msg,
    this.alunoNome,
    required this.isDark,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    assert(isDark || !isDark);
    assert(ink.a >= 0 && mute.a >= 0);
    final who = alunoNome?.trim();
    final title =
        (who != null && who.isNotEmpty)
            ? who
            : chatRemetenteLabel(
              remetente: msg.remetente,
              isAlunoMode: false,
              tipoMidia: msg.tipoMidia,
            );
    return FxSatelliteListTile(
      title: title,
      subtitle: Text(msg.conteudo),
      trailing: Text(
        fxTimeAgo(msg.enviadoEm),
        style: FocuxHubTypography.bodyMuted(
          color: mute,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        if (msg.alunoId != null) {
          context.push('/alunos/${msg.alunoId}/chat');
        }
      },
    );
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
    assert(isDark || !isDark);
    final preview = chatInboxPreview(
      remetente: item.ultimoRemetente,
      mensagem: item.ultimaMensagem,
    );
    final unread = item.naoLidas;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onLongPress: onLongPress,
      child: FxSatelliteListTile(
        title: item.alunoNome,
        subtitle: Text(preview),
        leading:
            selecting && selected
                ? Icon(Icons.check_rounded, color: primary)
                : AlunoAvatar(
                  name: item.alunoNome,
                  photoUrl: item.fotoUrl,
                  variant: AlunoAvatarVariant.strip,
                ),
        trailing: Text(
          unread > 0
              ? (unread > 99 ? '99+' : '$unread')
              : fxTimeAgo(item.enviadoEm),
          style: FocuxHubTypography.bodyMuted(
            color: unread > 0 ? primary : fxScreenMute(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        accent: unread > 0 || selected ? primary : null,
        onTap: onTap,
      ),
    );
  }
}

class _InboxTabPane extends StatelessWidget {
  const _InboxTabPane({
    required this.async,
    required this.isDark,
    required this.primary,
    required this.view,
    required this.selectionActive,
    required this.selectedAlunoIds,
    required this.onRetry,
    required this.onRefresh,
    required this.onConversationAction,
    required this.onOpenThread,
    required this.onToggleSelection,
    this.showLoadMore = false,
    this.loadingMore = false,
    this.onLoadMore,
  });

  final AsyncValue<List<ChatInboxItem>> async;
  final bool isDark;
  final Color primary;
  final ChatInboxHubView view;
  final bool selectionActive;
  final Set<int> selectedAlunoIds;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int alunoId, String action) onConversationAction;
  final void Function(int alunoId, {Object? extra}) onOpenThread;
  final ValueChanged<int> onToggleSelection;
  final bool showLoadMore;
  final bool loadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final isArchived = view == ChatInboxHubView.arquivadas;
    return async.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(TokensStrip.s4),
            child: SkeletonList(count: 6),
          ),
      error:
          (e, _) => FxErrorState(
            chromeOnDark: isDark,
            primary: primary,
            message: friendlyError(e),
            onRetry: onRetry,
          ),
      data: (items) {
        if (items.isEmpty) {
          // Sticky "Nova conversa" é o único CTA (§11) — empty quieto no topo.
          return FxEmptyState(
            icon: isArchived ? 'article' : 'chat',
            title: chatInboxEmptyTitle(view),
            subtitle: chatInboxEmptySubtitle(view),
            quiet: true,
          );
        }
        return RefreshIndicator(
          color: primary,
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
              FxSettingsLayout.pageInset,
              TokensStrip.s6,
            ),
            itemCount: items.length + (showLoadMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (showLoadMore && i >= items.length) {
                return FxSatelliteListTile(
                  title: loadingMore ? 'Carregando…' : 'Carregar mais',
                  onTap: () {
                    if (loadingMore) return;
                    onLoadMore?.call();
                  },
                );
              }
              final item = items[i];
              return Dismissible(
                key: Key('inbox-${item.alunoId}'),
                direction:
                    selectionActive
                        ? DismissDirection.none
                        : DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await onConversationAction(
                      item.alunoId,
                      isArchived ? 'unarchive' : 'archive',
                    );
                    return false;
                  }
                  await onConversationAction(item.alunoId, 'pin');
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 24),
                  color: primary.withValues(alpha: 0.12),
                  child: Icon(Icons.push_pin, color: primary),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: EagleTokens.warn.withValues(alpha: 0.12),
                  child: Icon(
                    isArchived ? Icons.unarchive : Icons.archive,
                    color: EagleTokens.warn,
                  ),
                ),
                child: _InboxTile(
                  item: item,
                  isDark: isDark,
                  selected: selectedAlunoIds.contains(item.alunoId),
                  selecting: selectionActive,
                  onTap: () {
                    if (selectionActive) {
                      onToggleSelection(item.alunoId);
                      return;
                    }
                    onOpenThread(item.alunoId, extra: item.alunoNome);
                  },
                  onLongPress: () => onToggleSelection(item.alunoId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
