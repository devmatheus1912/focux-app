part of 'conversation_screen.dart';

extension ConversationScreenOutbox on _ConversationScreenState {
  /// Mostra a bolha otimista e envia. Se falhar, a bolha fica como
  /// "Não enviada" com o conteúdo intacto para reenviar ou apagar.
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

  Future<void> _retryOutgoing(ChatMsg msg) async {
    final clientId = msg.clientMessageId;
    if (clientId == null || !_outbox.isFailed(clientId)) return;
    final media = msg.tipoMidia != 'TEXTO';
    if (media && _uploading) return;
    HapticFeedback.selectionClick();
    await _dispatchOutgoing(clientId, media: media);
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
      if (chatClientIdConfirmed(_msgs, clientId)) {
        _outbox.forget(clientId);
        return;
      }
      setState(() {});
      FeedbackHelper.showApiFailure(
        context,
        e,
        fallback: S.of(context).chatEnvioFalhou,
      );
    } finally {
      if (media && mounted) setState(() => _uploading = false);
    }
  }
}
