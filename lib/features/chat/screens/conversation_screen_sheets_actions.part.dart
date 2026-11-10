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
                  if (formatChatTextForDisplay(msg.conteudo).isNotEmpty) ...[
                    Text(
                      formatChatTextForDisplay(msg.conteudo),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.bodyMuted(
                        color: ShellChrome.of(sheetContext).mute,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                  ],
                  if (canInteract) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final emoji
                              in _ConversationScreenState._quickReactions)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: TokensStrip.s2,
                              ),
                              child: InkWell(
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
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(FxIcons.responder, color: primary),
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
                        FxIcons.copiar,
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
                      leading: Icon(FxIcons.editar, color: primary),
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
                        FxIcons.excluir,
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
                        FxIcons.meta,
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

  Future<void> _showAttachmentSheet() async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: 'Enviar',
      icone: FxIcons.adicionar,
      grupos: [
        FxActionGroup<String>(null, const [
          FxActionItem(valor: 'foto', rotulo: 'Tirar foto', icone: FxIcons.camera),
          FxActionItem(valor: 'filmar', rotulo: 'Filmar', icone: FxIcons.video),
          FxActionItem(
            valor: 'galeria',
            rotulo: 'Galeria',
            descricao: 'Foto ou vídeo',
            icone: FxIcons.galeria,
          ),
        ]),
      ],
    );
    if (!mounted || escolha == null) return;
    switch (escolha) {
      case 'foto':
        await _pickAndSend(ConversationMediaType.photo, source: ImageSource.camera);
      case 'filmar':
        await _pickAndSend(ConversationMediaType.video, source: ImageSource.camera);
      case 'galeria':
        await _pickAndSend(null);
    }
  }
}
