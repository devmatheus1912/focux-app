part of 'conversation_screen.dart';

extension ConversationScreenOutbox on _ConversationScreenState {
  /// Mostra a bolha otimista e envia. Se falhar, a bolha fica como
  /// "Não enviada" com o conteúdo intacto para reenviar ou descartar.
  Future<void> _sendOutgoing(
    ChatMsg optimistic,
    ChatSendOperation send, {
    bool media = false,
  }) async {
    final clientId = optimistic.clientMessageId!;
    _outbox.track(clientId, send);
    setState(() {
      _replyingTo = null;
      _upsertMessage(optimistic);
    });
    _scrollToBottom();
    await _dispatchOutgoing(clientId, media: media);
  }

  Future<void> _sendMediaOutgoing(
    ChatMsg optimistic,
    Future<String> Function() upload,
  ) {
    final repo = ChatRepository(ref.read(apiClientProvider));
    final alunoId = optimistic.alunoId;
    return _sendOutgoing(
      optimistic,
      media: true,
      chatMediaSendOperation(
        upload: upload,
        send:
            (url, scope) =>
                _isAlunoMode
                    ? repo.enviarMidiaComoAluno(
                      conteudo: optimistic.conteudo,
                      tipoMidia: optimistic.tipoMidia!,
                      midiaUrl: url,
                      idempotencyScope: scope,
                      replyToMessageId: optimistic.replyToMessageId,
                      clientMessageId: optimistic.clientMessageId,
                    )
                    : repo.enviarMidia(
                      alunoId: alunoId!,
                      conteudo: optimistic.conteudo,
                      remetente: 'PERSONAL',
                      tipoMidia: optimistic.tipoMidia!,
                      midiaUrl: url,
                      idempotencyScope: scope,
                      replyToMessageId: optimistic.replyToMessageId,
                      clientMessageId: optimistic.clientMessageId,
                    ),
      ),
    );
  }

  void _dedupeInitialDraft() {
    if (_initialDraftChecked) return;
    _initialDraftChecked = true;
    final draft = widget.initialDraft?.trim();
    if (draft == null || draft.isEmpty) return;
    if (!_isDuplicateOutgoing(draft)) return;
    setState(() {
      _ctrl.clear();
      _composerHasText = false;
    });
    FeedbackHelper.showSuccess(context, 'Mensagem recente já existe no chat.');
  }

  bool _isDuplicateOutgoing(String text) {
    final recentMine = _msgs.reversed
        .take(8)
        .where((m) => _isMine(m) && !_outbox.isFailed(m.clientMessageId))
        .map((m) => m.conteudo);
    return isRecentDuplicateOutgoing(text, recentMine);
  }

  /// Um anexo por vez: reenviar mídia espera o upload em curso terminar.
  bool _canRetryOutgoing(ChatMsg msg) =>
      !(_uploading && isChatMediaMessage(msg));

  Future<void> _retryOutgoing(ChatMsg msg) async {
    final clientId = msg.clientMessageId;
    if (clientId == null || !_outbox.isFailed(clientId)) return;
    if (!_canRetryOutgoing(msg)) return;
    HapticFeedback.selectionClick();
    await _dispatchOutgoing(clientId, media: isChatMediaMessage(msg));
  }

  void _discardOutgoing(ChatMsg msg) {
    final clientId = msg.clientMessageId;
    if (clientId == null || !_outbox.isFailed(clientId)) return;
    HapticFeedback.selectionClick();
    _outbox.forget(clientId);
    setState(() {
      _msgs.removeWhere((m) => m.clientMessageId == clientId && m.id == null);
    });
  }

  Future<void> _dispatchOutgoing(String clientId, {required bool media}) async {
    setState(() {
      if (media) _uploading = true;
    });
    try {
      final msg = await _outbox.dispatch(clientId);
      if (msg == null) return;
      _captureAlunoId(msg);
      if (!mounted) return;
      setState(() => _upsertMessage(msg));
      _scrollToBottom();
      _ackPersonalContactBestEffort();
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      switch (_outbox.phaseOf(clientId)) {
        case ChatSendPhase.gone:
          return;
        case ChatSendPhase.sending:
          _recheckInFlight(clientId);
        case ChatSendPhase.failed:
          FeedbackHelper.showApiFailure(
            context,
            e,
            fallback: S.of(context).chatEnvioFalhou,
          );
      }
    } finally {
      if (media && mounted) setState(() => _uploading = false);
    }
  }

  /// `409`: a primeira tentativa ainda processa no servidor. Reconsulta com a
  /// mesma chave; o upload já terminou, então só o POST se repete.
  void _recheckInFlight(String clientId) {
    unawaited(
      Future<void>.delayed(chatInFlightRecheckDelay, () async {
        if (!mounted || _outbox.phaseOf(clientId) != ChatSendPhase.sending) {
          return;
        }
        await _dispatchOutgoing(clientId, media: false);
      }),
    );
  }
}
