part of 'conversation_screen.dart';

extension ConversationScreenSheets on _ConversationScreenState {
void _showMessageActions(ChatMsg msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final canInteract = msg.deletedAt == null;
    final canEdit = _canEditMessage(msg);
    final canDelete = _canDeleteMessage(msg);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                    ),
                    child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: TokensStrip.s4),
                      if (canInteract) ...[
                        Text(
                          'Reagir',
                          style: TextStyle(
                            color:
                                isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final emoji in _ConversationScreenState._quickReactions)
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _toggleReaction(msg, emoji);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: primarySoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.reply_rounded, color: primary),
                          title: const Text('Responder'),
                          onTap: () {
                            Navigator.pop(context);
                            _setReply(msg);
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.content_copy_outlined,
                            color: primary,
                          ),
                          title: const Text('Copiar mensagem'),
                          onTap: () async {
                            Navigator.pop(context);
                            await Clipboard.setData(
                              ClipboardData(
                                text: formatChatTextForDisplay(msg.conteudo),
                              ),
                            );
                            if (!mounted) return;
                            FeedbackHelper.showSnackBar(
                              context,
                              const SnackBar(content: Text('Mensagem copiada')),
                            );
                          },
                        ),
                      ],
                      if (canEdit)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined, color: primary),
                          title: const Text('Editar mensagem'),
                          onTap: () {
                            Navigator.pop(context);
                            _editMessage(msg);
                          },
                        ),
                      if (canDelete)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFE5484D),
                          ),
                          title: const Text('Apagar mensagem'),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteMessage(msg);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  void _showEmojiSheet() {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary);
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
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  context,
                  accent: primary,
                  radius: TokensStrip.rXl,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 24),
                    child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final emoji in _ConversationScreenState._quickReactions)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        final next = '${_ctrl.text}$emoji';
                        _ctrl.value = TextEditingValue(
                          text: next,
                          selection: TextSelection.collapsed(
                            offset: next.length,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
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

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  context,
                  accent: primary,
                  radius: TokensStrip.rXl,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 20),
                    child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConversationAttachOption(
                    icon: Icons.photo_camera_outlined,
                    label: 'Foto da galeria',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSend(ConversationMediaType.photo);
                    },
                  ),
                  const SizedBox(height: 8),
                  ConversationAttachOption(
                    icon: Icons.videocam_outlined,
                    label: 'Video da galeria',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSend(ConversationMediaType.video);
                    },
                  ),
                  const SizedBox(height: 8),
                  ConversationAttachOption(
                    icon: Icons.mic_none_outlined,
                    label: 'Gravar audio',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _startAudioRecording();
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

  void _showSearchSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ctrl = TextEditingController();
    var query = '';
    var searching = false;
    var searched = false;
    var results = <ChatMsg>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              final media = MediaQuery.of(sheetContext);
              final keyboardInset = media.viewInsets.bottom;
              final availableHeight =
                  media.size.height - keyboardInset - media.padding.top - 32;
              final sheetHeight = availableHeight.clamp(280.0, 440.0);

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.rXl),
                  child: DecoratedBox(
                    decoration: fxListCardDecoration(
                      context,
                      accent: primary,
                      radius: TokensStrip.rXl,
                    ),
                    child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 16),
                    child: SizedBox(
                      height: sheetHeight,
                      child: Column(
                        children: [
                          Container(
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
                          const SizedBox(height: TokensStrip.s4),
                          TextField(
                            controller: ctrl,
                            autofocus: true,
                            onChanged:
                                (value) => setSheetState(() => query = value),
                            onSubmitted: (_) async {
                              await _performSearch(
                                query: query,
                                setSearching:
                                    (value) =>
                                        setSheetState(() => searching = value),
                                setResults:
                                    (value) => setSheetState(() {
                                      searched = true;
                                      results = value;
                                    }),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar na conversa',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  await _performSearch(
                                    query: query,
                                    setSearching:
                                        (value) => setSheetState(
                                          () => searching = value,
                                        ),
                                    setResults:
                                        (value) => setSheetState(() {
                                          searched = true;
                                          results = value;
                                        }),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward_rounded),
                              ),
                              filled: true,
                              fillColor:
                                  isDark
                                      ? EagleTokens.darkCardHi
                                      : TokensStrip.cardBg,
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child:
                                query.trim().isEmpty
                                    ? const ConversationSearchState(
                                      icon: Icons.search_rounded,
                                      title: 'Digite para buscar',
                                      subtitle:
                                          'Encontre mensagens antigas da conversa.',
                                    )
                                    : searching
                                    ? const Center(child: FxLoading())
                                    : searched && results.isEmpty
                                    ? const ConversationSearchState(
                                      icon: Icons.chat_bubble_outline,
                                      title: 'Nada encontrado',
                                      subtitle: 'Tente outra palavra-chave.',
                                    )
                                    : ListView.separated(
                                      itemCount: results.length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (_, index) {
                                        final msg = results[index];
                                        return InkWell(
                                          onTap: () {
                                            Navigator.pop(sheetContext);
                                            _focusMessage(msg);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  isDark
                                                      ? EagleTokens.darkCardHi
                                                      : primarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _replySenderLabel(
                                                    msg.remetente,
                                                  ),
                                                  style: TextStyle(
                                                    color: primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _previewText(msg),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _fullDateLabel(msg.enviadoEm),
                                                  style: TextStyle(
                                                    color:
                                                        isDark
                                                            ? EagleTokens
                                                                .darkInkMute
                                                            : EagleTokens
                                                                .inkMute,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              );
            },
          ),
    ).whenComplete(ctrl.dispose);
  }

  Future<void> _performSearch({
    required String query,
    required void Function(bool value) setSearching,
    required void Function(List<ChatMsg> value) setResults,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      setResults(const []);
      return;
    }
    setSearching(true);
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final results =
          _isAlunoMode
              ? await repo.buscarHistoricoAluno(normalized)
              : await repo.buscarHistorico(_alunoId!, normalized);
      setResults(results);
    } catch (_) {
      final fallback = _msgs.reversed
          .where((msg) {
            final content = msg.conteudo.toLowerCase();
            final reply = (msg.replyToConteudo ?? '').toLowerCase();
            return content.contains(normalized.toLowerCase()) ||
                reply.contains(normalized.toLowerCase());
          })
          .toList(growable: false);
      setResults(fallback);
    } finally {
      setSearching(false);
    }
  }

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
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  context,
                  accent: primary,
                  radius: TokensStrip.rXl,
                ),
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

  String _messageIdentity(ChatMsg msg) {
    return msg.id?.toString() ??
        msg.clientMessageId ??
        '${msg.enviadoEm.microsecondsSinceEpoch}-${msg.conteudo.hashCode}';
  }

  GlobalKey _messageKey(ChatMsg msg) {
    final identity = _messageIdentity(msg);
    return _messageKeys.putIfAbsent(identity, GlobalKey.new);
  }

  String _displayName(PersonalBrand? brand) {
    if (_isPersonalMode) {
      return widget.alunoNome ?? 'Aluno';
    }
    return brand?.nomePersonal.isNotEmpty == true
        ? brand!.nomePersonal
        : 'Seu personal';
  }

  String _subtitle(PersonalBrand? brand) {
    if (_isPersonalMode) {
      return 'Treino, ajustes e feedback em um so lugar';
    }
    return brand?.slogan?.trim().isNotEmpty == true
        ? brand!.slogan!
        : 'Canal direto com seu personal';
  }

  String? _avatarImage(PersonalBrand? brand) {
    if (_isPersonalMode) {
      return null;
    }
    return brand?.logoUrl;
  }

  String _replySenderLabel(String remetente) {
    if (_isAlunoMode) {
      return remetente == 'ALUNO' ? 'Voce' : 'Personal';
    }
    return remetente == 'PERSONAL' ? 'Voce' : 'Aluno';
  }

  String _previewText(ChatMsg msg) {
    if (msg.deletedAt != null) return 'Mensagem apagada';
    final displayText = formatChatTextForDisplay(msg.conteudo);
    if (displayText.isNotEmpty &&
        !_isMediaLabelOnly(msg.primaryMediaType, msg.conteudo)) {
      return displayText;
    }
    if (msg.primaryMediaType == 'IMAGE') return 'Foto';
    if (msg.primaryMediaType == 'VIDEO') return 'Video';
    if (msg.primaryMediaType == 'AUDIO') return 'Audio';
    return 'Mensagem';
  }

  String _mediaType(ConversationMediaType type) {
    switch (type) {
      case ConversationMediaType.photo:
        return 'IMAGE';
      case ConversationMediaType.video:
        return 'VIDEO';
      case ConversationMediaType.audio:
        return 'AUDIO';
    }
  }

  String _mediaLabel(ConversationMediaType type) {
    switch (type) {
      case ConversationMediaType.photo:
        return 'Foto';
      case ConversationMediaType.video:
        return 'Video';
      case ConversationMediaType.audio:
        return 'Audio';
    }
  }

  bool _isMediaLabelOnly(String? tipoMidia, String conteudo) {
    if (tipoMidia == null) return false;
    return ['IMAGE', 'IMAGEM', 'VIDEO', 'AUDIO'].contains(tipoMidia);
  }

  bool _canEditMessage(ChatMsg msg) {
    return msg.id != null &&
        _isMine(msg) &&
        msg.deletedAt == null &&
        (msg.primaryMediaUrl == null || msg.primaryMediaUrl!.isEmpty) &&
        msg.conteudo.trim().isNotEmpty &&
        !_isMediaLabelOnly(msg.primaryMediaType, msg.conteudo);
  }

  bool _canDeleteMessage(ChatMsg msg) {
    return msg.id != null && _isMine(msg) && msg.deletedAt == null;
  }

  void _upsertMessage(ChatMsg msg) {
    final byId = msg.id != null ? _msgs.indexWhere((m) => m.id == msg.id) : -1;
    if (byId >= 0) {
      _msgs[byId] = msg;
      _msgs.sort((a, b) => a.enviadoEm.compareTo(b.enviadoEm));
      return;
    }
    final byClient =
        msg.clientMessageId != null
            ? _msgs.indexWhere((m) => m.clientMessageId == msg.clientMessageId)
            : -1;
    if (byClient >= 0) {
      _msgs[byClient] = msg;
      _msgs.sort((a, b) => a.enviadoEm.compareTo(b.enviadoEm));
      return;
    }
    _msgs.add(msg);
    _msgs.sort((a, b) => a.enviadoEm.compareTo(b.enviadoEm));
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final offset = _scroll.position.maxScrollExtent;
      if (!animated) {
        _scroll.jumpTo(offset);
        return;
      }
      _scroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  String _fullDateLabel(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
