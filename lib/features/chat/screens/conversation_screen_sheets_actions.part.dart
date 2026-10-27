part of 'conversation_screen.dart';

extension ConversationScreenSheetsActions on _ConversationScreenState {
  void _showMessageActions(ChatMsg msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final canInteract = chatCanReplyTo(msg);
    final canCopy = msg.deletedAt == null;
    final canEdit = _canEditMessage(msg);
    final canDelete = _canDeleteMessage(msg);
    final canReport =
        msg.id != null &&
        msg.deletedAt == null &&
        !_isMine(msg) &&
        !chatIsSistema(msg.remetente, msg.tipoMidia);
    showFxHomeSheet<void>(
      context,
      builder:
          (sheetContext) => FxHomeSheetSurface(
            isDark: isDark,
            maxHeight:
                MediaQuery.sizeOf(sheetContext).height *
                FxHomeSheetChrome.maxHeightFactor,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FxHomeSheetHandle(isDark: isDark),
                  SizedBox(height: TokensStrip.s4),
                  if (canInteract) ...[
                    Text(
                      'Reagir',
                      style: TextStyle(
                        color:
                            isDark
                                ? EagleTokens.darkInk
                                : TokensStrip.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final emoji
                            in _ConversationScreenState._quickReactions)
                          InkWell(
                            onTap: () {
                              Navigator.pop(sheetContext);
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
                        Navigator.pop(sheetContext);
                        _setReply(msg);
                      },
                    ),
                  ],
                  if (canCopy)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.content_copy_outlined,
                        color: primary,
                      ),
                      title: const Text('Copiar mensagem'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await Clipboard.setData(
                          ClipboardData(
                            text: formatChatTextForDisplay(msg.conteudo),
                          ),
                        );
                        if (!mounted) return;
                        FeedbackHelper.showSuccess(context, 'Mensagem copiada');
                      },
                    ),
                  if (canEdit)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined, color: primary),
                      title: const Text('Editar mensagem'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _editMessage(msg);
                      },
                    ),
                  if (canDelete)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: EagleTokens.bad,
                      ),
                      title: const Text('Apagar mensagem'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _deleteMessage(msg);
                      },
                    ),
                  if (canReport)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.flag_outlined,
                        color: EagleTokens.bad,
                      ),
                      title: Text(S.of(context).moderacaoDenunciarMensagem),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showDenunciarSheet(
                          context,
                          repo: ModeracaoRepository(
                            ref.read(apiClientProvider),
                          ),
                          tipo: DenunciaTipo.chatMensagem,
                          alvoId: '${msg.id}',
                          conteudo: formatChatTextForDisplay(msg.conteudo),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  void _showEmojiSheet() {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showFxHomeSheet<void>(
      context,
      builder:
          (sheetContext) => FxHomeSheetSurface(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                SizedBox(height: TokensStrip.s4),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final emoji
                        in _ConversationScreenState._quickReactions)
                      InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext);
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
              ],
            ),
          ),
    );
  }

  Future<void> _showAttachmentSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final choice = await showFxHomeSheet<Object>(
      context,
      builder:
          (sheetContext) => FxHomeSheetSurface(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                SizedBox(height: TokensStrip.s4),
                for (final (icone, rotulo, valor) in <(IconData, String, Object)>[
                  (
                    Icons.photo_camera_outlined,
                    'Tirar foto',
                    (ConversationMediaType.photo, ImageSource.camera),
                  ),
                  (
                    Icons.videocam_outlined,
                    'Filmar',
                    (ConversationMediaType.video, ImageSource.camera),
                  ),
                  (
                    Icons.photo_library_outlined,
                    'Foto da galeria',
                    (ConversationMediaType.photo, ImageSource.gallery),
                  ),
                  (
                    Icons.video_library_outlined,
                    'Vídeo da galeria',
                    (ConversationMediaType.video, ImageSource.gallery),
                  ),
                  (Icons.mic_none_outlined, 'Gravar áudio', 'audio'),
                ]) ...[
                  ConversationAttachOption(
                    icon: icone,
                    label: rotulo,
                    isDark: isDark,
                    onTap: () => Navigator.pop(sheetContext, valor),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'audio') {
      await _startAudioRecording();
      return;
    }
    if (choice is (ConversationMediaType, ImageSource)) {
      await _pickAndSend(choice.$1, source: choice.$2);
    }
  }
}
