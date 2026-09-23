part of 'conversation_screen.dart';

extension ConversationScreenMessaging on _ConversationScreenState {
  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _uploading) return;
    FxKeyboardDismissScope.dismiss();
    if (_isDuplicateOutgoing(text)) {
      HapticFeedback.selectionClick();
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Mensagem recente ja enviada.');
      }
      return;
    }
    if (!_isAlunoMode && _alunoId == null) {
      FeedbackHelper.showError(context, 'Conversa sem aluno. Reabra o chat.');
      return;
    }

    final replyToMessageId = _replyingTo?.id;
    final replyPreview = _replyingTo;
    final repo = ChatRepository(ref.read(apiClientProvider));
    final clientId = repo.newClientMessageId();
    final optimistic = ChatMsg(
      alunoId: _alunoId,
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
    setState(() {
      _composerHasText = false;
      _replyingTo = null;
      _upsertMessage(optimistic);
    });
    _scrollToBottom();

    try {
      final msg =
          _isAlunoMode
              ? await repo.enviarComoAluno(
                text,
                replyToMessageId: replyToMessageId,
                clientMessageId: clientId,
              )
              : await repo.enviar(
                _alunoId!,
                text,
                'PERSONAL',
                replyToMessageId: replyToMessageId,
                clientMessageId: clientId,
              );
      _captureAlunoId(msg);
      if (!mounted) return;
      setState(() => _upsertMessage(msg));
      _ackPersonalContactBestEffort();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msgs.removeWhere((m) => m.clientMessageId == clientId && m.id == null);
      });
      FeedbackHelper.showError(context, friendlyError(e));
    }
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
    FeedbackHelper.showSuccess(context, 'Mensagem recente ja existe no chat.');
  }

  bool _isDuplicateOutgoing(String text) {
    final normalized = _normalizeOutgoingText(text);
    if (normalized.isEmpty) return false;
    for (final msg in _msgs.reversed.take(8)) {
      if (!_isMine(msg)) continue;
      final sent = _normalizeOutgoingText(msg.conteudo);
      if (sent == normalized || _looksLikeSameCopilotAction(sent, normalized)) {
        return true;
      }
    }
    return false;
  }

  String _normalizeOutgoingText(String value) {
    return normalizeChatText(
      value,
    ).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  bool _looksLikeSameCopilotAction(String a, String b) {
    final aWords = _meaningfulWords(a);
    final bWords = _meaningfulWords(b);
    if (aWords.length < 5 || bWords.length < 5) return false;
    final overlap = aWords.intersection(bWords).length;
    final smaller =
        aWords.length < bWords.length ? aWords.length : bWords.length;
    return overlap >= 5 && overlap / smaller >= 0.62;
  }

  Set<String> _meaningfulWords(String value) {
    const stop = {
      'oi',
      'me',
      'com',
      'para',
      'pelo',
      'pela',
      'seu',
      'sua',
      'que',
      'uma',
      'um',
      'agora',
      'quando',
      'fizer',
      'combinado',
      'responde',
      'aqui',
      'ok',
      'plano',
    };
    return value
        .split(RegExp(r'[^a-z0-9áéíóúâêôãõç]+', caseSensitive: false))
        .where((word) => word.length > 2 && !stop.contains(word))
        .toSet();
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

    final replyToMessageId = _replyingTo?.id;
    final filename = _safeUploadFilename(file, type);
    final resourceType =
        type == ConversationMediaType.photo
            ? 'image'
            : type == ConversationMediaType.video
            ? 'video'
            : 'auto';
    final repo = ChatRepository(ref.read(apiClientProvider));
    final clientId = repo.newClientMessageId();
    final optimistic = ChatMsg(
      alunoId: _alunoId,
      remetente: _isAlunoMode ? 'ALUNO' : 'PERSONAL',
      conteudo: _mediaLabel(type),
      enviadoEm: DateTime.now(),
      tipoMidia: _mediaType(type),
      clientMessageId: clientId,
      replyToMessageId: replyToMessageId,
    );

    setState(() {
      _uploading = true;
      _replyingTo = null;
      _upsertMessage(optimistic);
    });
    _scrollToBottom();

    try {
      final uploader = MediaUploadService(ref.read(apiClientProvider));
      final mediaUrl =
          kIsWeb || file.path.isEmpty
              ? await uploader.uploadBytes(
                bytes: await file.readAsBytes(),
                filename: filename,
                folder: 'chat',
                resourceType: resourceType,
              )
              : await uploader.uploadFile(
                path: file.path,
                filename: filename,
                folder: 'chat',
                resourceType: resourceType,
              );
      final msg =
          _isAlunoMode
              ? await repo.enviarMidiaComoAluno(
                conteudo: _mediaLabel(type),
                tipoMidia: _mediaType(type),
                midiaUrl: mediaUrl,
                replyToMessageId: replyToMessageId,
                clientMessageId: clientId,
              )
              : await repo.enviarMidia(
                alunoId: _alunoId!,
                conteudo: _mediaLabel(type),
                remetente: 'PERSONAL',
                tipoMidia: _mediaType(type),
                midiaUrl: mediaUrl,
                replyToMessageId: replyToMessageId,
                clientMessageId: clientId,
              );
      _captureAlunoId(msg);
      if (!mounted) return;
      setState(() => _upsertMessage(msg));
      _scrollToBottom();
      _ackPersonalContactBestEffort();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msgs.removeWhere((m) => m.clientMessageId == clientId && m.id == null);
      });
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
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
      return;
    }
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      FeedbackHelper.showError(context, 'Audio vazio. Grave novamente.');
      return;
    }

    try {
      final file = XFile(
        path,
        mimeType: kIsWeb ? 'audio/webm' : 'audio/mp4',
        name: path.split(RegExp(r'[\\/]')).last,
      );
      await _sendAudioBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        duration: duration,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível enviar o áudio.'),
      );
    }
  }

  Future<void> _sendAudioBytes({
    required List<int> bytes,
    required String filename,
    required Duration duration,
  }) async {
    final replyToMessageId = _replyingTo?.id;
    setState(() => _uploading = true);
    try {
      final mediaUrl = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: bytes,
        filename: filename,
        folder: 'chat/audio',
        resourceType: 'auto',
      );
      final repo = ChatRepository(ref.read(apiClientProvider));
      final label = 'Audio ${_formatDuration(duration)}';
      final msg =
          _isAlunoMode
              ? await repo.enviarMidiaComoAluno(
                conteudo: label,
                tipoMidia: 'AUDIO',
                midiaUrl: mediaUrl,
                replyToMessageId: replyToMessageId,
              )
              : await repo.enviarMidia(
                alunoId: _alunoId!,
                conteudo: label,
                remetente: 'PERSONAL',
                tipoMidia: 'AUDIO',
                midiaUrl: mediaUrl,
                replyToMessageId: replyToMessageId,
              );
      _captureAlunoId(msg);
      if (!mounted) return;
      setState(() {
        _replyingTo = null;
        _upsertMessage(msg);
      });
      HapticFeedback.mediumImpact();
      _scrollToBottom();
      _ackPersonalContactBestEffort();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
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
        FeedbackHelper.showSuccess(context, 'Nao foi possivel reagir: $e');
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
    ref.invalidate(aluno360Provider(alunoId));
  }

  void _setReply(ChatMsg msg) {
    if (msg.deletedAt != null) return;
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
        'Mensagem original nao encontrada aqui.',
      );
      return;
    }
    _focusMessage(original);
  }
}
