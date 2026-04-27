import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/config/env.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';

enum ConversationMode { personal, aluno }

class ConversationScreen extends ConsumerStatefulWidget {
  final ConversationMode mode;
  final int? alunoId;
  final String? alunoNome;

  const ConversationScreen.personal({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  })  : mode = ConversationMode.personal,
        assert(alunoId != null),
        assert(alunoNome != null);

  const ConversationScreen.aluno({super.key})
      : mode = ConversationMode.aluno,
        alunoId = null,
        alunoNome = null;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final List<ChatMsg> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  StompClient? _stomp;
  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  bool _composerHasText = false;
  int? _alunoId;

  bool get _isAlunoMode => widget.mode == ConversationMode.aluno;
  bool get _isPersonalMode => widget.mode == ConversationMode.personal;

  @override
  void initState() {
    super.initState();
    _alunoId = widget.alunoId;
    _ctrl.addListener(_handleComposerChange);
    _loadHistorico();
    if (_alunoId != null) {
      _connectWs(_alunoId!);
    }
  }

  void _handleComposerChange() {
    final next = _ctrl.text.trim().isNotEmpty;
    if (next != _composerHasText && mounted) {
      setState(() => _composerHasText = next);
    }
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    _ctrl.removeListener(_handleComposerChange);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistorico() async {
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final msgs = _isAlunoMode
          ? await repo.historicoAluno()
          : await repo.historico(_alunoId!);
      if (_isAlunoMode && msgs.isNotEmpty && _alunoId == null) {
        _alunoId = msgs.first.alunoId;
        if (_alunoId != null) {
          _connectWs(_alunoId!);
        }
      }
      if (mounted) {
        setState(() {
          _msgs
            ..clear()
            ..addAll(msgs);
          _loading = false;
        });
      }
      await _markRead();
      _scrollToBottom(animated: false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markRead() async {
    final repo = ChatRepository(ref.read(apiClientProvider));
    if (_isAlunoMode) {
      await repo.marcarLidoAluno();
      return;
    }
    if (_alunoId != null) {
      await repo.marcarLido(_alunoId!);
    }
  }

  Future<void> _connectWs(int alunoId) async {
    if (_stomp != null) {
      return;
    }
    final token = await SecureStorage.getToken();
    final url = '${Env.wsUrl}/ws/websocket';
    _stomp = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (frame) => _onConnect(frame, alunoId),
        beforeConnect: () async {},
        onStompError: (_) {},
        onDisconnect: (_) {},
        stompConnectHeaders:
            token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders:
            token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
    _stomp!.activate();
  }

  void _onConnect(StompFrame frame, int alunoId) {
    _stomp?.subscribe(
      destination: '/topic/chat.$alunoId',
      callback: (f) async {
        if (f.body == null) return;
        try {
          final data = jsonDecode(f.body!) as Map<String, dynamic>;
          final msg = ChatMsg.fromJson(data);
          if (!mounted) return;
          setState(() => _upsertMessage(msg));
          if (_isIncoming(msg)) {
            await _markRead();
          }
          _scrollToBottom();
        } catch (_) {
          await _loadHistorico();
        }
      },
    );
  }

  bool _isIncoming(ChatMsg msg) {
    return _isAlunoMode ? msg.remetente == 'PERSONAL' : msg.remetente == 'ALUNO';
  }

  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _uploading) return;
    _ctrl.clear();
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final msg = _isAlunoMode
          ? await repo.enviarComoAluno(text)
          : await repo.enviar(_alunoId!, text, 'PERSONAL');
      _captureAlunoId(msg);
      if (mounted) {
        setState(() => _upsertMessage(msg));
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _captureAlunoId(ChatMsg msg) {
    if (_alunoId == null && msg.alunoId != null) {
      _alunoId = msg.alunoId;
      _connectWs(msg.alunoId!);
    }
  }

  Future<void> _pickAndSend(MediaType type) async {
    XFile? file;
    try {
      if (type == MediaType.photo) {
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 86,
        );
      } else if (type == MediaType.video) {
        file = await _picker.pickVideo(source: ImageSource.gallery);
      } else {
        file = await _picker.pickMedia();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nao foi possivel selecionar o arquivo: $e')),
        );
      }
      return;
    }
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final mediaUrl = await MediaUploadService(ref.read(apiClientProvider))
          .uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'chat',
        resourceType: type == MediaType.photo ? 'image' : 'auto',
      );
      final repo = ChatRepository(ref.read(apiClientProvider));
      final msg = _isAlunoMode
          ? await repo.enviarMidiaComoAluno(
              conteudo: _mediaLabel(type),
              tipoMidia: _mediaType(type),
              midiaUrl: mediaUrl,
            )
          : await repo.enviarMidia(
              alunoId: _alunoId!,
              conteudo: _mediaLabel(type),
              remetente: 'PERSONAL',
              tipoMidia: _mediaType(type),
              midiaUrl: mediaUrl,
            );
      _captureAlunoId(msg);
      if (mounted) {
        setState(() => _upsertMessage(msg));
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar midia: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String _mediaType(MediaType type) {
    switch (type) {
      case MediaType.photo:
        return 'IMAGE';
      case MediaType.video:
        return 'VIDEO';
      case MediaType.audio:
        return 'AUDIO';
    }
  }

  String _mediaLabel(MediaType type) {
    switch (type) {
      case MediaType.photo:
        return 'Foto';
      case MediaType.video:
        return 'Video';
      case MediaType.audio:
        return 'Audio';
    }
  }

  void _upsertMessage(ChatMsg msg) {
    final byId = msg.id != null ? _msgs.indexWhere((m) => m.id == msg.id) : -1;
    if (byId >= 0) {
      _msgs[byId] = msg;
      _msgs.sort((a, b) => a.enviadoEm.compareTo(b.enviadoEm));
      return;
    }
    final byClient = msg.clientMessageId != null
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

  void _showEmojiSheet() {
    const emojis = ['🔥', '👏', '💪', '✅', '🙌', '🚀', '🙂', '😅', '❤️', '👊'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final emoji in emojis)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    final next = '${_ctrl.text}$emoji';
                    _ctrl.value = TextEditingValue(
                      text: next,
                      selection: TextSelection.collapsed(offset: next.length),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EagleTokens.brand.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              _AttachOption(
                icon: Icons.photo_camera_outlined,
                label: 'Foto',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSend(MediaType.photo);
                },
              ),
              const SizedBox(height: 8),
              _AttachOption(
                icon: Icons.videocam_outlined,
                label: 'Video',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSend(MediaType.video);
                },
              ),
              const SizedBox(height: 8),
              _AttachOption(
                icon: Icons.mic_none_outlined,
                label: 'Audio',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSend(MediaType.audio);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isPersonalMode)
              ListTile(
                leading:
                    const Icon(Icons.person_outline, color: EagleTokens.brand),
                title: const Text('Ver perfil do aluno'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/alunos/${widget.alunoId}');
                },
              ),
            ListTile(
              leading: const Icon(Icons.refresh, color: EagleTokens.brand),
              title: const Text('Atualizar conversa'),
              onTap: () {
                Navigator.pop(context);
                _loadHistorico();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.emoji_emotions_outlined, color: EagleTokens.brand),
              title: const Text('Adicionar emoji'),
              onTap: () {
                Navigator.pop(context);
                _showEmojiSheet();
              },
            ),
          ],
        ),
      ),
    );
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
      return 'Conversa ativa';
    }
    return brand?.slogan?.trim().isNotEmpty == true
        ? brand!.slogan!
        : 'Acompanhamento no app';
  }

  String? _avatarImage(PersonalBrand? brand) {
    if (_isPersonalMode) {
      return null;
    }
    return brand?.logoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = _isAlunoMode ? ref.watch(personalBrandProvider).valueOrNull : null;
    final title = _displayName(brand);
    final subtitle = _subtitle(brand);

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: EagleTokens.brand.withValues(alpha: 0.12),
              backgroundImage: _avatarImage(brand) == null
                  ? null
                  : NetworkImage(_avatarImage(brand)!),
              child: _avatarImage(brand) == null
                  ? Text(
                      fxInitials(title),
                      style: const TextStyle(
                        color: EagleTokens.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showEmojiSheet,
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
          ),
          IconButton(
            onPressed: _showChatMenu,
            icon: const Icon(Icons.more_horiz),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_uploading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: EagleTokens.brand.withValues(alpha: 0.10),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EagleTokens.brand,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Enviando midia...',
                    style: TextStyle(
                      color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: EagleTokens.brand),
                  )
                : _msgs.isEmpty
                    ? _EmptyConversation(
                        isDark: isDark,
                        title: 'Comece uma conversa',
                        subtitle:
                            'As mensagens do treino vao aparecer aqui em tempo real.',
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: _msgs.length,
                        itemBuilder: (_, index) {
                          final msg = _msgs[index];
                          final previous =
                              index > 0 ? _msgs[index - 1] : null;
                          final showDate = previous == null ||
                              !_sameDay(previous.enviadoEm, msg.enviadoEm);
                          return Column(
                            children: [
                              if (showDate)
                                _DateDivider(date: msg.enviadoEm),
                              _Bubble(
                                msg: msg,
                                mine: _isAlunoMode
                                    ? msg.remetente == 'ALUNO'
                                    : msg.remetente == 'PERSONAL',
                                isDark: isDark,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              10 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? EagleTokens.darkBg : EagleTokens.paper,
              border: Border(
                top: BorderSide(
                  color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: (_sending || _uploading) ? null : _showAttachmentSheet,
                  icon: const Icon(Icons.add_circle),
                  color: EagleTokens.inkMute,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            style: TextStyle(
                              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                              fontSize: 15,
                            ),
                            cursorColor: EagleTokens.brand,
                            decoration: InputDecoration(
                              hintText: 'Mensagem',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? EagleTokens.darkInkMute
                                    : EagleTokens.inkMute,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendText(),
                          ),
                        ),
                        IconButton(
                          onPressed: _showEmojiSheet,
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          color: EagleTokens.inkMute,
                        ),
                        if (_composerHasText || _sending)
                          Padding(
                            padding: const EdgeInsets.only(right: 6, bottom: 6),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: EagleTokens.brand,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: (_sending || _uploading) ? null : _sendText,
                                icon: _sending
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }
}

enum MediaType { photo, video, audio }

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: EagleTokens.brand),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _EmptyConversation({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: EagleTokens.brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: EagleTokens.brand,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final label =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  final bool mine;
  final bool isDark;

  const _Bubble({
    required this.msg,
    required this.mine,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        mine ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink);
    final metaColor = mine
        ? Colors.white.withValues(alpha: 0.75)
        : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [EagleTokens.brand, EagleTokens.brandInk],
                )
              : null,
          color: mine
              ? null
              : (isDark ? EagleTokens.darkCardHi : EagleTokens.card),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 8),
            bottomRight: Radius.circular(mine ? 8 : 20),
          ),
          border: mine
              ? null
              : Border.all(
                  color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MediaPreview(msg: msg, mine: mine, isDark: isDark),
            if (msg.conteudo.isNotEmpty &&
                !_isMediaLabelOnly(msg.tipoMidia, msg.conteudo))
              Text(
                msg.conteudo,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(msg.enviadoEm),
                  style: TextStyle(color: metaColor, fontSize: 11),
                ),
                if (mine) ...[
                  const SizedBox(width: 6),
                  Text(
                    _statusLabel(msg),
                    style: TextStyle(color: metaColor, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isMediaLabelOnly(String? tipoMidia, String conteudo) {
    if (tipoMidia == null) return false;
    return ['IMAGE', 'IMAGEM', 'VIDEO', 'AUDIO'].contains(tipoMidia);
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(ChatMsg msg) {
    if (msg.readAt != null) return 'Lido';
    if (msg.deliveredAt != null) return 'Entregue';
    return 'Enviado';
  }
}

class _MediaPreview extends StatelessWidget {
  final ChatMsg msg;
  final bool mine;
  final bool isDark;

  const _MediaPreview({
    required this.msg,
    required this.mine,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = msg.tipoMidia;
    final url = msg.midiaUrl;
    if (tipo == null || url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    if (tipo == 'IMAGE' || tipo == 'IMAGEM') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            url,
            height: 200,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              width: 220,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      );
    }

    IconData icon = Icons.insert_drive_file_outlined;
    String label = 'Arquivo';
    if (tipo == 'VIDEO') {
      icon = Icons.play_circle_outline;
      label = 'Video';
    } else if (tipo == 'AUDIO') {
      icon = Icons.graphic_eq_outlined;
      label = 'Audio';
    }

    final textColor =
        mine ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine
              ? Colors.white.withValues(alpha: 0.12)
              : EagleTokens.brand.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
