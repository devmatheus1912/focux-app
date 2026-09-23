part of 'conversation_screen.dart';

extension ConversationScreenSheetsHelpers on _ConversationScreenState {
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
      return 'Treino e ajustes';
    }
    return brand?.slogan?.trim().isNotEmpty == true
        ? brand!.slogan!
        : 'Mensagens do treino';
  }

  String? _avatarImage(PersonalBrand? brand, {String? alunoFotoUrl}) {
    if (_isPersonalMode) {
      return alunoFotoUrl;
    }
    return brand?.logoUrl;
  }

  String _replySenderLabel(String remetente) {
    return chatRemetenteLabel(remetente: remetente, isAlunoMode: _isAlunoMode);
  }

  String _previewText(ChatMsg msg) {
    if (msg.deletedAt != null) return 'Mensagem apagada';
    if (chatIsSistema(msg.remetente, msg.tipoMidia)) {
      return formatChatSystemEvent(msg.conteudo).threadLabel;
    }
    final displayText = formatChatTextForDisplay(msg.conteudo);
    if (displayText.isNotEmpty &&
        !_isMediaLabelOnly(msg.primaryMediaType, msg.conteudo)) {
      return displayText;
    }
    if (msg.primaryMediaType == 'IMAGE') return 'Foto';
    if (msg.primaryMediaType == 'VIDEO') return 'Vídeo';
    if (msg.primaryMediaType == 'AUDIO') return 'Áudio';
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
        return 'Vídeo';
      case ConversationMediaType.audio:
        return 'Áudio';
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
