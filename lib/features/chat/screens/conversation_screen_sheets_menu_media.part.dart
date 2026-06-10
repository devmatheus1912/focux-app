part of 'conversation_screen.dart';

extension ConversationScreenSheetsMenuMedia on _ConversationScreenState {
  void _showChatMenu() {
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TokensStrip.rXl),
              child: fxListTileCardShell(
                context: context,
                accent: primary,
                radius: TokensStrip.rXl,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isPersonalMode)
                  ListTile(
                    leading: Icon(Icons.person_outline, color: primary),
                    title: const Text('Ver perfil do aluno'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/alunos/${widget.alunoId}');
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.search_rounded, color: primary),
                  title: const Text('Buscar conversa'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSearchSheet();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.perm_media_outlined, color: primary),
                  title: const Text('Midias da conversa'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMediaGallerySheet();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.refresh, color: primary),
                  title: const Text('Atualizar conversa'),
                  onTap: () {
                    Navigator.pop(context);
                    _loadHistorico();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.emoji_emotions_outlined, color: primary),
                  title: const Text('Adicionar emoji'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEmojiSheet();
                  },
                ),
              ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TokensStrip.rXl),
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  context,
                  accent: primary,
                  radius: TokensStrip.rXl,
                ),
                child: SafeArea(
                  child: StatefulBuilder(
              builder: (context, setSheetState) {
                final items = filtered(selected);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 18),
                  child: SizedBox(
                    height: MediaQuery.of(sheetContext).size.height * 0.72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? EagleTokens.darkLine
                                      : TokensStrip.borderDefault,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Midias da conversa',
                          style: TextStyle(
                            color:
                                isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
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
                                onTap:
                                    () => setSheetState(() => selected = null),
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
                    ),
                  ),
                );
              },
                  ),
                ),
              ),
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
    final opened = await launchUrlString(url);
    if (!opened && mounted) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Nao foi possivel abrir o anexo.')),
      );
    }
  }

  void _showImageViewer(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.85,
                  maxScale: 3.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => Container(
                            height: 240,
                            alignment: Alignment.center,
                            decoration: fxListCardDecoration(context),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
