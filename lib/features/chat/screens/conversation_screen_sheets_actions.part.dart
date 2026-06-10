part of 'conversation_screen.dart';

extension ConversationScreenSheetsActions on _ConversationScreenState {
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
              child: fxListTileCardShell(
                context: context,
                accent: primary,
                radius: TokensStrip.rXl,
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
                            FeedbackHelper.showSuccess(context, 'Mensagem copiada');
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
                            color: EagleTokens.bad,
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
}
