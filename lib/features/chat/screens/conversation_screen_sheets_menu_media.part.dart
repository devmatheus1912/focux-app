part of 'conversation_screen.dart';

extension ConversationScreenSheetsMenuMedia on _ConversationScreenState {
  Future<void> _showChatMenu() async {
    final items = <FxInsetPickerSheetItem<String>>[
      if (_isPersonalMode)
        const FxInsetPickerSheetItem(
          value: 'perfil',
          label: 'Ver perfil do aluno',
          subtitle: 'Abrir o Aluno 360',
          icon: Icons.person_outline_rounded,
        ),
      const FxInsetPickerSheetItem(
        value: 'buscar',
        label: 'Buscar conversa',
        subtitle: 'Encontrar mensagem na thread',
        icon: Icons.search_rounded,
      ),
      const FxInsetPickerSheetItem(
        value: 'midias',
        label: 'Mídias da conversa',
        subtitle: 'Fotos, vídeos e áudios',
        icon: Icons.perm_media_outlined,
      ),
      const FxInsetPickerSheetItem(
        value: 'atualizar',
        label: 'Atualizar conversa',
        subtitle: 'Recarregar mensagens',
        icon: Icons.refresh_rounded,
      ),
      const FxInsetPickerSheetItem(
        value: 'emoji',
        label: 'Adicionar emoji',
        subtitle: 'Inserir no campo de mensagem',
        icon: Icons.emoji_emotions_outlined,
      ),
    ];
    final chosen = await showFxInsetPickerSheet<String>(
      context,
      title: 'Conversa',
      headerIcon: Icons.more_horiz_rounded,
      selected: null,
      items: items,
    );
    if (chosen == null || !mounted) return;
    HapticFeedback.selectionClick();
    switch (chosen) {
      case 'perfil':
        context.push('/alunos/${widget.alunoId}');
      case 'buscar':
        _showSearchSheet();
      case 'midias':
        _showMediaGallerySheet();
      case 'atualizar':
        _loadHistorico();
      case 'emoji':
        _showEmojiSheet();
    }
  }

  void _showMediaGallerySheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    ConversationMediaType? selected;

    List<ChatMsg> filtered(ConversationMediaType? type) {
      return _msgs
          .where((msg) {
            final tipo = msg.primaryMediaType;
            final url = msg.primaryMediaUrl;
            if (tipo == null || url == null || url.isEmpty) return false;
            if (type == null) return true;
            return _mediaType(type) == tipo ||
                (type == ConversationMediaType.photo && tipo == 'IMAGEM');
          })
          .toList(growable: false)
          .reversed
          .toList(growable: false);
    }

    showFxHomeSheet<void>(
      context,
      builder:
          (sheetContext) => FxHomeSheetSurface(
            isDark: isDark,
            maxHeight:
                MediaQuery.sizeOf(sheetContext).height *
                FxHomeSheetChrome.maxHeightFactor,
            expand: true,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final items = filtered(selected);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FxHomeSheetHandle(isDark: isDark),
                    SizedBox(height: TokensStrip.s4),
                    FxHomeSheetHeader(
                      isDark: isDark,
                      title: 'Midias da conversa',
                      leading: Icon(
                        Icons.perm_media_outlined,
                        color: primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ConversationMediaFilterChip(
                            label: 'Tudo',
                            selected: selected == null,
                            onTap: () => setSheetState(() => selected = null),
                            primary: primary,
                            isDark: isDark,
                          ),
                          ConversationMediaFilterChip(
                            label: 'Fotos',
                            selected: selected == ConversationMediaType.photo,
                            onTap:
                                () => setSheetState(
                                  () => selected = ConversationMediaType.photo,
                                ),
                            primary: primary,
                            isDark: isDark,
                          ),
                          ConversationMediaFilterChip(
                            label: 'Videos',
                            selected: selected == ConversationMediaType.video,
                            onTap:
                                () => setSheetState(
                                  () => selected = ConversationMediaType.video,
                                ),
                            primary: primary,
                            isDark: isDark,
                          ),
                          ConversationMediaFilterChip(
                            label: 'Audios',
                            selected: selected == ConversationMediaType.audio,
                            onTap:
                                () => setSheetState(
                                  () => selected = ConversationMediaType.audio,
                                ),
                            primary: primary,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child:
                          items.isEmpty
                              ? const ConversationSearchState(
                                icon: Icons.perm_media_outlined,
                                title: 'Sem midias aqui',
                                subtitle:
                                    'Fotos, videos e audios enviados aparecerao nesta area.',
                              )
                              : ListView.separated(
                                itemCount: items.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final msg = items[index];
                                  return ConversationMediaGalleryTile(
                                    msg: msg,
                                    isDark: isDark,
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      _focusMessage(msg);
                                      _openMedia(msg);
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  Future<void> _openMedia(ChatMsg msg) async {
    final url = msg.primaryMediaUrl;
    if (url == null || url.isEmpty) return;
    final tipo = msg.primaryMediaType;
    if (tipo == 'IMAGE' || tipo == 'IMAGEM') {
      _showImageViewer(url);
      return;
    }
    final opened = await launchSafeHttpUrl(url);
    if (!opened && mounted) {
      FeedbackHelper.showError(context, 'Nao foi possivel abrir o anexo.');
    }
  }

  void _showImageViewer(String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: isDark,
          expand: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Foto',
                leading: const Icon(Icons.image_outlined, size: 18),
              ),
              SizedBox(height: TokensStrip.s3),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.85,
                  maxScale: 3.5,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(TokensStrip.rCard),
                      child: FxCachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Container(
                              height: 240,
                              alignment: Alignment.center,
                              decoration: fxListCardDecoration(ctx),
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 32,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
