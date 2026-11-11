part of 'chat_inbox_screen.dart';

class _AlunoPickerSheet extends ConsumerStatefulWidget {
  const _AlunoPickerSheet({
    required this.onSelect,
    required this.conversas,
    required this.inboxCompleto,
  });

  final ValueChanged<Aluno> onSelect;

  /// Conversas já carregadas no inbox, por aluno (para a prévia da linha).
  final Map<int, ChatInboxItem> conversas;

  /// Inbox sem página por carregar: dá para afirmar "Sem conversa ainda".
  final bool inboxCompleto;

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
    final alunosAsync = ref.watch(alunosParaConversaProvider);
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
          FxHomeSheetHeader(isDark: isDark, title: 'Nova conversa'),
          const SizedBox(height: 8),
          FxSheetSearchField(
            dica: 'Buscar aluno',
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: alunosAsync.when(
              loading: () => const SkeletonList(count: 6),
              error:
                  (e, _) => FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: friendlyError(e),
                    onRetry: () => ref.invalidate(alunosParaConversaProvider),
                  ),
              data: _buildAlunos,
            ),
          ),
        ],
      ),
    );
  }

  /// Prévia da linha: o motivo de atenção, a última mensagem ou "Sem conversa
  /// ainda" (só quando o inbox inteiro carregou; senão, nada).
  String? _subtitulo(Aluno aluno, {required bool atencao}) {
    if (atencao) return alunoMotivoAtencao(aluno);
    final conversa = widget.conversas[aluno.id];
    if (conversa != null) {
      return chatInboxPreview(
        remetente: conversa.ultimoRemetente,
        mensagem: conversa.ultimaMensagem,
      );
    }
    return widget.inboxCompleto ? 'Sem conversa ainda' : null;
  }

  Widget _buildAlunos(List<Aluno> alunos) {
    final grupos = gruposDaNovaConversa(alunos, _query);
    if (grupos.precisam.isEmpty && grupos.todos.isEmpty) {
      return FxEmptyState(
        icon: _query.isEmpty ? FxIcons.grupo : FxIcons.buscar,
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
    Widget linha(Aluno a, {required bool atencao}) => _AlunoContactTile(
      aluno: a,
      subtitulo: _subtitulo(a, atencao: atencao),
      atencao: atencao,
      onTap: () => widget.onSelect(a),
    );
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (grupos.precisam.isNotEmpty) ...[
          _CabecalhoDaFolha('Precisam de você'),
          for (final a in grupos.precisam) linha(a, atencao: true),
          const SizedBox(height: TokensStrip.s3),
          if (grupos.todos.isNotEmpty) _CabecalhoDaFolha('Todos'),
        ],
        for (final a in grupos.todos) linha(a, atencao: false),
      ],
    );
  }
}

class _CabecalhoDaFolha extends StatelessWidget {
  const _CabecalhoDaFolha(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.groupPadH,
        TokensStrip.s1,
        FxSettingsLayout.groupPadH,
        TokensStrip.s2,
      ),
      child: Text(
        texto,
        style: FxSettingsLayout.sectionHeader(color: fxScreenMute(context)),
      ),
    );
  }
}

/// Linha de aluno na folha e no "Comece uma conversa": mesma pele do inbox
/// (avatar à esquerda, prévia embaixo, seta), sem e-mail nem "Abrir".
class _AlunoContactTile extends StatelessWidget {
  const _AlunoContactTile({
    required this.aluno,
    required this.subtitulo,
    required this.onTap,
    this.atencao = false,
  });

  final Aluno aluno;
  final String? subtitulo;
  final VoidCallback onTap;
  final bool atencao;

  @override
  Widget build(BuildContext context) {
    final sub = subtitulo;
    return FxSatelliteListTile(
      margin: const EdgeInsets.only(bottom: 4),
      title: fxTitleCaseName(aluno.nome),
      subtitle:
          sub == null
              ? null
              : Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    atencao
                        ? FocuxHubTypography.bodyMuted(
                          color: EagleTokens.warn,
                          fontWeight: FontWeight.w600,
                        )
                        : null,
              ),
      leading: AlunoAvatar(
        name: aluno.nome,
        photoUrl: aluno.fotoUrl,
        variant: AlunoAvatarVariant.strip,
      ),
      trailing: Icon(FxIcons.chevronDireita, color: fxScreenMute(context)),
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
          context.push('/chat/inbox/conversa/${msg.alunoId}');
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
    return FxSatelliteListTile(
      margin: const EdgeInsets.only(bottom: 4),
      title: item.alunoNome,
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      leading:
          selecting && selected
              ? Icon(FxIcons.check, color: primary)
              : AlunoAvatar(
                name: item.alunoNome,
                photoUrl: item.fotoUrl,
                variant: AlunoAvatarVariant.strip,
              ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fxTimeAgo(item.enviadoEm),
            style: FocuxHubTypography.bodyMuted(
              color: unread > 0 ? primary : fxScreenMute(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(height: TokensStrip.s1),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensStrip.s2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(TokensStrip.rPill),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: FocuxHubTypography.chip(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
      accent: unread > 0 || selected ? primary : null,
      onTap: onTap,
      onLongPress: onLongPress,
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
    this.rodape,
  });

  /// "Comece uma conversa" (aba Todas, inbox inteiro carregado).
  final Widget? rodape;

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
          final vazio = FxEmptyState(
            icon: isArchived ? FxIcons.artigo : FxIcons.chat,
            title: chatInboxEmptyTitle(view),
            subtitle: chatInboxEmptySubtitle(view),
            quiet: true,
          );
          final extra = rodape;
          if (extra == null) return vazio;
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.pageInset,
            ),
            children: [vazio, extra],
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
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s5,
            ),
            itemCount:
                items.length +
                (showLoadMore ? 1 : 0) +
                (rodape == null ? 0 : 1),
            itemBuilder: (context, i) {
              if (rodape != null &&
                  i == items.length + (showLoadMore ? 1 : 0)) {
                return rodape!;
              }
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
                  child: Icon(FxIcons.fixadoAtivo, color: primary),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: EagleTokens.warn.withValues(alpha: 0.12),
                  child: Icon(
                    isArchived ? FxIcons.desarquivar : FxIcons.arquivar,
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

/// Fim da aba Todas: até 3 alunos sem conversa (quem precisa de você antes) e
/// "Ver todos os alunos", ao alcance do polegar, sem botão flutuante.
class _ComeceUmaConversa extends StatelessWidget {
  const _ComeceUmaConversa({
    required this.alunos,
    required this.onAbrir,
    required this.onVerTodos,
  });

  final List<Aluno> alunos;
  final ValueChanged<Aluno> onAbrir;
  final VoidCallback onVerTodos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CabecalhoDaFolha('Comece uma conversa'),
          for (final a in alunos)
            _AlunoContactTile(
              aluno: a,
              subtitulo: alunoMotivoAtencao(a) ?? 'Sem conversa ainda',
              atencao: alunoPrecisaDeVoce(a),
              onTap: () => onAbrir(a),
            ),
          FxSatelliteListTile(
            title: 'Ver todos os alunos',
            titleCase: false,
            trailing: Icon(
              FxIcons.chevronDireita,
              color: fxScreenMute(context),
            ),
            onTap: onVerTodos,
          ),
        ],
      ),
    );
  }
}
