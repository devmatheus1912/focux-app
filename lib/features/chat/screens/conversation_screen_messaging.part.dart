part of 'conversation_screen.dart';

extension ConversationScreenMessaging on _ConversationScreenState {
  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _uploading) return;
    FxKeyboardDismissScope.dismiss();
    final failedTwin = _outbox.failedWithText(_msgs, text);
    if (failedTwin != null) {
      _ctrl.clear();
      setState(() => _replyingTo = null);
      await _retryOutgoing(failedTwin);
      return;
    }
    if (_isDuplicateOutgoing(text)) {
      HapticFeedback.selectionClick();
      if (mounted) {
        FeedbackHelper.showInfo(context, 'Mensagem recente já enviada.');
      }
      return;
    }
    if (!_isAlunoMode && _alunoId == null) {
      FeedbackHelper.showError(context, 'Conversa sem aluno. Reabra o chat.');
      return;
    }

    final replyToMessageId = _replyingTo?.id;
    final replyPreview = _replyingTo;
    final alunoId = _alunoId;
    final repo = ChatRepository(ref.read(apiClientProvider));
    final clientId = repo.newClientMessageId();
    final optimistic = ChatMsg(
      alunoId: alunoId,
      remetente: _isAlunoMode ? 'ALUNO' : 'PERSONAL',
      conteudo: text,
      enviadoEm: DateTime.now(),
      tipoMidia: 'TEXTO',
      clientMessageId: clientId,
      replyToMessageId: replyToMessageId,
      replyToConteudo: replyPreview?.conteudo,
      replyToRemetente: replyPreview?.remetente,
    );

    _ctrl.clear();
    HapticFeedback.lightImpact();
    _composerHasText = false;
    await _sendOutgoing(
      optimistic,
      (scope) =>
          _isAlunoMode
              ? repo.enviarComoAluno(
                text,
                idempotencyScope: scope,
                replyToMessageId: replyToMessageId,
                clientMessageId: clientId,
              )
              : repo.enviar(
                alunoId!,
                text,
                'PERSONAL',
                idempotencyScope: scope,
                replyToMessageId: replyToMessageId,
                clientMessageId: clientId,
              ),
    );
  }

  /// Captura actions/id no frame atual (ainda montado); o Future usa Ref do
  /// Provider — não toca State após unmount.
  void _ackPersonalContactBestEffort() {
    if (_isAlunoMode) return;
    final alunoId = _alunoId;
    if (alunoId == null) return;
    final actions = ref.read(alunoFollowUpActionsProvider);
    unawaited(actions.markContactDoneBestEffort(alunoId));
  }

  void _captureAlunoId(ChatMsg msg) {
    if (_alunoId == null && msg.alunoId != null) {
      _alunoId = msg.alunoId;
      _connectWs(msg.alunoId!);
    }
  }

  String _safeUploadFilename(XFile file, ConversationMediaType type) {
    final name = file.name.trim();
    if (name.contains('.')) return name;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return switch (type) {
      ConversationMediaType.photo => 'foto_$stamp.jpg',
      ConversationMediaType.video => 'video_$stamp.mp4',
      ConversationMediaType.audio => 'audio_$stamp.m4a',
    };
  }

  Future<void> _pickAndSend(ConversationMediaType type) async {
    if (_uploading) return;
    if (!_isAlunoMode && _alunoId == null) {
      FeedbackHelper.showError(context, 'Conversa sem aluno. Reabra o chat.');
      return;
    }

    XFile? file;
    try {
      if (type == ConversationMediaType.photo) {
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 72,
        );
      } else if (type == ConversationMediaType.video) {
        file = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 60),
        );
      } else {
        file = await _picker.pickMedia();
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível selecionar o arquivo.'),
        );
      }
      return;
    }
    if (file == null) return;

    final size = await file.length();
    const maxChatBytes = 80 * 1024 * 1024;
    if (size <= 0) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Arquivo vazio.');
      }
      return;
    }
    if (size > maxChatBytes) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          type == ConversationMediaType.video
              ? 'Vídeo acima de 80 MB. Envie um trecho mais curto.'
              : 'Arquivo acima de 80 MB.',
        );
      }
      return;
    }

    final filename = _safeUploadFilename(file, type);
    final resourceType =
        type == ConversationMediaType.photo
            ? 'image'
            : type == ConversationMediaType.video
            ? 'video'
            : 'auto';
    final picked = file;
    final uploader = MediaUploadService(ref.read(apiClientProvider));
    final optimistic = ChatMsg(
      alunoId: _alunoId,
      remetente: _isAlunoMode ? 'ALUNO' : 'PERSONAL',
      conteudo: _mediaLabel(type),
      enviadoEm: DateTime.now(),
      tipoMidia: _mediaType(type),
      clientMessageId:
          ChatRepository(ref.read(apiClientProvider)).newClientMessageId(),
      replyToMessageId: _replyingTo?.id,
    );

    await _sendMediaOutgoing(
      optimistic,
      () async =>
          kIsWeb || picked.path.isEmpty
              ? uploader.uploadBytes(
                bytes: await picked.readAsBytes(),
                filename: filename,
                folder: 'chat',
                resourceType: resourceType,
              )
              : uploader.uploadFile(
                path: picked.path,
                filename: filename,
                folder: 'chat',
                resourceType: resourceType,
              ),
    );
  }

  Future<void> _startAudioRecording() async {
    if (_recordingAudio || _uploading) return;
    try {
      final allowed = await _audioRecorder.hasPermission();
      if (!allowed) {
        if (!mounted) return;
        FeedbackHelper.showError(
          context,
          'Permita o microfone para gravar audio.',
        );
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final extension = kIsWeb ? 'webm' : 'm4a';
      final filename = 'focux_audio_$now.$extension';
      final path =
          kIsWeb
              ? filename
              : '${(await getTemporaryDirectory()).path}/$filename';

      await _audioRecorder.start(
        RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );

      HapticFeedback.mediumImpact();
      _recordTimer?.cancel();
      setState(() {
        _recordingAudio = true;
        _recordDuration = Duration.zero;
        _recordStartedAt = DateTime.now();
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _recordStartedAt == null) return;
        setState(() {
          _recordDuration = DateTime.now().difference(_recordStartedAt!);
        });
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível iniciar o áudio.'),
      );
    }
  }

  Future<void> _stopAudioRecording({required bool send}) async {
    if (!_recordingAudio) return;
    final duration =
        _recordStartedAt == null
            ? _recordDuration
            : DateTime.now().difference(_recordStartedAt!);

    _recordTimer?.cancel();
    setState(() {
      _recordingAudio = false;
      _recordDuration = duration;
      _recordStartedAt = null;
    });

    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível finalizar o áudio.'),
      );
      return;
    }

    if (!send) {
      HapticFeedback.selectionClick();
      _deleteRecordedAudio(path);
      return;
    }
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      FeedbackHelper.showError(context, 'Áudio vazio. Grave novamente.');
      return;
    }

    try {
      final file = XFile(
        path,
        mimeType: kIsWeb ? 'audio/webm' : 'audio/mp4',
        name: path.split(RegExp(r'[\\/]')).last,
      );
      final bytes = await file.readAsBytes();
      await _sendAudioBytes(
        bytes: bytes,
        filename: file.name,
        duration: duration,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível enviar o áudio.'),
      );
    } finally {
      _deleteRecordedAudio(path);
    }
  }

  /// Os bytes já estão em memória (e na operação de reenvio): o arquivo
  /// temporário da gravação não precisa ficar no aparelho.
  void _deleteRecordedAudio(String? path) {
    if (kIsWeb || path == null || path.isEmpty) return;
    unawaited(File(path).delete().then((_) {}, onError: (Object _) {}));
  }

  Future<void> _sendAudioBytes({
    required List<int> bytes,
    required String filename,
    required Duration duration,
  }) async {
    final uploader = MediaUploadService(ref.read(apiClientProvider));
    final optimistic = ChatMsg(
      alunoId: _alunoId,
      remetente: _isAlunoMode ? 'ALUNO' : 'PERSONAL',
      conteudo: 'Áudio ${_formatDuration(duration)}',
      enviadoEm: DateTime.now(),
      tipoMidia: 'AUDIO',
      clientMessageId:
          ChatRepository(ref.read(apiClientProvider)).newClientMessageId(),
      replyToMessageId: _replyingTo?.id,
    );

    HapticFeedback.mediumImpact();
    await _sendMediaOutgoing(
      optimistic,
      () => uploader.uploadBytes(
        bytes: bytes,
        filename: filename,
        folder: 'chat/audio',
        resourceType: 'auto',
      ),
    );
  }

  Future<void> _toggleReaction(ChatMsg msg, String emoji) async {
    if (msg.id == null || msg.deletedAt != null) return;
    HapticFeedback.selectionClick();
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final updated =
          _isAlunoMode
              ? await repo.toggleReactionAluno(msg.id!, emoji)
              : await repo.toggleReaction(msg.id!, emoji);
      if (!mounted) return;
      setState(() => _upsertMessage(updated));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: S.of(context).chatReacaoFalhou),
        );
      }
    }
  }

  Future<void> _editMessage(ChatMsg msg) async {
    if (!_canEditMessage(msg)) return;
    final ctrl = TextEditingController(
      text: formatChatTextForDisplay(msg.conteudo),
    );
    final saved = await showFxFormSheet(
      context,
      title: 'Editar mensagem',
      icon: Icons.edit_outlined,
      confirmLabel: 'Salvar',
      child: TextField(
        controller: ctrl,
        autofocus: true,
        minLines: 1,
        maxLines: 5,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(hintText: 'Digite sua mensagem…'),
      ),
    );
    final next = saved ? ctrl.text : null;
    ctrl.dispose();
    final normalized = next?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        normalized == msg.conteudo.trim()) {
      return;
    }
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final updated =
          _isAlunoMode
              ? await repo.editarMensagemAluno(msg.id!, normalized)
              : await repo.editarMensagem(msg.id!, normalized);
      if (!mounted) return;
      setState(() => _upsertMessage(updated));
      _invalidateAluno360Timeline();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, 'Não foi possível editar a mensagem.');
    }
  }

  Future<void> _deleteMessage(ChatMsg msg) async {
    if (!_canDeleteMessage(msg)) return;
    final confirmed = await showFxConfirmSheet(
      context,
      title: 'Apagar mensagem?',
      message: 'A conversa vai mostrar que a mensagem foi apagada.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final updated =
          _isAlunoMode
              ? await repo.apagarMensagemAluno(msg.id!)
              : await repo.apagarMensagem(msg.id!);
      if (!mounted) return;
      setState(() => _upsertMessage(updated));
      _invalidateAluno360Timeline();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, 'Não foi possível apagar a mensagem.');
    }
  }

  void _invalidateAluno360Timeline() {
    if (_isAlunoMode) return;
    final alunoId = _alunoId ?? widget.alunoId;
    if (alunoId == null) return;
    ref.invalidate(alunoTimeline360PagedProvider(alunoId));
  }

  void _setReply(ChatMsg msg) {
    if (!chatCanReplyTo(msg)) return;
    HapticFeedback.selectionClick();
    setState(() => _replyingTo = msg);
  }

  void _focusMessage(ChatMsg msg) {
    if (!mounted || msg.id == null) return;
    setState(() => _highlightedMessageId = msg.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _messageKeys[_messageIdentity(msg)];
      final context = key?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      }
    });
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted && _highlightedMessageId == msg.id) {
          setState(() => _highlightedMessageId = null);
        }
      }),
    );
  }

  ChatMsg? _findMessageById(int? messageId) {
    if (messageId == null) return null;
    for (final msg in _msgs) {
      if (msg.id == messageId) {
        return msg;
      }
    }
    return null;
  }

  void _jumpToReplySource(ChatMsg msg) {
    final original = _findMessageById(msg.replyToMessageId);
    if (original == null) {
      FeedbackHelper.showInfo(
        context,
        'Mensagem original não encontrada aqui.',
      );
      return;
    }
    _focusMessage(original);
  }
}
