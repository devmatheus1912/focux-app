import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import '../../../core/utils/friendly_error.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/config/env.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';
import '../data/chat_text_formatter.dart';

enum ConversationMode { personal, aluno }

class ConversationScreen extends ConsumerStatefulWidget {
  final ConversationMode mode;
  final int? alunoId;
  final String? alunoNome;

  const ConversationScreen.personal({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  }) : mode = ConversationMode.personal,
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
  static const _quickReactions = [
    '\u{1F525}',
    '\u{1F44F}',
    '\u{1F4AA}',
    '\u{2705}',
    '\u{1F64C}',
    '\u{1F680}',
    '\u{1F642}',
    '\u{1F605}',
    '\u{2764}\u{FE0F}',
    '\u{1F44A}',
  ];

  final List<ChatMsg> _msgs = [];
  final Map<String, GlobalKey> _messageKeys = {};
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  StompClient? _stomp;
  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  bool _recordingAudio = false;
  bool _composerHasText = false;
  bool _loadingOlder = false;
  bool _loadFailed = false;
  bool _hasMoreMessages = false;
  int? _alunoId;
  int? _nextBeforeId;
  ChatMsg? _replyingTo;
  int? _highlightedMessageId;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;
  DateTime? _recordStartedAt;

  bool get _isAlunoMode => widget.mode == ConversationMode.aluno;
  bool get _isPersonalMode => widget.mode == ConversationMode.personal;

  @override
  void initState() {
    super.initState();
    _alunoId = widget.alunoId;
    _ctrl.addListener(_handleComposerChange);
    _scroll.addListener(_handleScroll);
    _loadHistorico();
    if (_alunoId != null) {
      _connectWs(_alunoId!);
    }
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    _recordTimer?.cancel();
    unawaited(_audioRecorder.dispose());
    _scroll.removeListener(_handleScroll);
    _ctrl.removeListener(_handleComposerChange);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleComposerChange() {
    final next = _ctrl.text.trim().isNotEmpty;
    if (next != _composerHasText && mounted) {
      setState(() => _composerHasText = next);
    }
  }

  void _handleScroll() {
    if (!_scroll.hasClients || _loading || _loadingOlder || !_hasMoreMessages) {
      return;
    }
    if (_scroll.position.pixels <= 120) {
      unawaited(_loadOlderMessages());
    }
  }

  Future<void> _loadHistorico() async {
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final page =
          _isAlunoMode
              ? await repo.historicoAlunoPage()
              : await repo.historicoPage(_alunoId!);
      final msgs = page.items;
      if (_isAlunoMode && msgs.isNotEmpty && _alunoId == null) {
        _alunoId = msgs.first.alunoId;
        if (_alunoId != null) {
          _connectWs(_alunoId!);
        }
      }
      if (!mounted) return;
      setState(() {
        _msgs
          ..clear()
          ..addAll(msgs);
        _nextBeforeId = page.nextBeforeId;
        _hasMoreMessages = page.hasMore;
        _loadFailed = false;
        _loading = false;
      });
      await _markRead();
      _scrollToBottom(animated: false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingOlder || !_hasMoreMessages || _nextBeforeId == null) return;
    final previousMax =
        _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    final previousOffset = _scroll.hasClients ? _scroll.offset : 0.0;
    setState(() => _loadingOlder = true);
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final page =
          _isAlunoMode
              ? await repo.historicoAlunoPage(beforeId: _nextBeforeId)
              : await repo.historicoPage(_alunoId!, beforeId: _nextBeforeId);
      if (!mounted) return;
      setState(() {
        for (final msg in page.items) {
          _upsertMessage(msg);
        }
        _nextBeforeId = page.nextBeforeId;
        _hasMoreMessages = page.hasMore;
        _loadingOlder = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final delta = _scroll.position.maxScrollExtent - previousMax;
        _scroll.jumpTo(previousOffset + delta);
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOlder = false);
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
    final destination =
        _isAlunoMode
            ? '/topic/chat.aluno.$alunoId'
            : '/topic/chat.personal.$alunoId';
    _stomp?.subscribe(
      destination: destination,
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
    return _isAlunoMode
        ? msg.remetente == 'PERSONAL'
        : msg.remetente == 'ALUNO';
  }

  bool _isMine(ChatMsg msg) {
    return _isAlunoMode
        ? msg.remetente == 'ALUNO'
        : msg.remetente == 'PERSONAL';
  }

  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _uploading) return;
    final replyToMessageId = _replyingTo?.id;
    _ctrl.clear();
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final msg =
          _isAlunoMode
              ? await repo.enviarComoAluno(
                text,
                replyToMessageId: replyToMessageId,
              )
              : await repo.enviar(
                _alunoId!,
                text,
                'PERSONAL',
                replyToMessageId: replyToMessageId,
              );
      _captureAlunoId(msg);
      if (!mounted) return;
      setState(() {
        _replyingTo = null;
        _upsertMessage(msg);
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
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

    final replyToMessageId = _replyingTo?.id;
    setState(() => _uploading = true);
    try {
      final mediaUrl = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'chat',
        resourceType: type == MediaType.photo ? 'image' : 'auto',
      );
      final repo = ChatRepository(ref.read(apiClientProvider));
      final msg =
          _isAlunoMode
              ? await repo.enviarMidiaComoAluno(
                conteudo: _mediaLabel(type),
                tipoMidia: _mediaType(type),
                midiaUrl: mediaUrl,
                replyToMessageId: replyToMessageId,
              )
              : await repo.enviarMidia(
                alunoId: _alunoId!,
                conteudo: _mediaLabel(type),
                remetente: 'PERSONAL',
                tipoMidia: _mediaType(type),
                midiaUrl: mediaUrl,
                replyToMessageId: replyToMessageId,
              );
      _captureAlunoId(msg);
      if (!mounted) return;
      setState(() {
        _replyingTo = null;
        _upsertMessage(msg);
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _startAudioRecording() async {
    if (_recordingAudio || _sending || _uploading) return;
    try {
      final allowed = await _audioRecorder.hasPermission();
      if (!allowed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permita o microfone para gravar audio.'),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel iniciar o audio: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel finalizar o audio: $e')),
      );
      return;
    }

    if (!send) {
      HapticFeedback.selectionClick();
      return;
    }
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio vazio. Grave novamente.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel enviar o audio: $e')),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Nao foi possivel reagir: $e')));
      }
    }
  }

  Future<void> _editMessage(ChatMsg msg) async {
    if (!_canEditMessage(msg)) return;
    final ctrl = TextEditingController(text: msg.conteudo);
    final next = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Editar mensagem'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(hintText: 'Mensagem'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, ctrl.text),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nao foi possivel editar: $e')));
    }
  }

  Future<void> _deleteMessage(ChatMsg msg) async {
    if (!_canDeleteMessage(msg)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Apagar mensagem?'),
            content: const Text(
              'A conversa vai mostrar que a mensagem foi apagada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Apagar'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final updated =
          _isAlunoMode
              ? await repo.apagarMensagemAluno(msg.id!)
              : await repo.apagarMensagem(msg.id!);
      if (!mounted) return;
      setState(() => _upsertMessage(updated));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nao foi possivel apagar: $e')));
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem original nao encontrada aqui.')),
      );
      return;
    }
    _focusMessage(original);
  }

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
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.72,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
                                    : EagleTokens.line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (canInteract) ...[
                        Text(
                          'Reagir',
                          style: TextStyle(
                            color:
                                isDark ? EagleTokens.darkInk : EagleTokens.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final emoji in _quickReactions)
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
                              ClipboardData(text: msg.conteudo),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
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
    );
  }

  void _showEmojiSheet() {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final emoji in _quickReactions)
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
      builder:
          (_) => SafeArea(
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
                    label: 'Foto da galeria',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSend(MediaType.photo);
                    },
                  ),
                  const SizedBox(height: 8),
                  _AttachOption(
                    icon: Icons.videocam_outlined,
                    label: 'Video da galeria',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSend(MediaType.video);
                    },
                  ),
                  const SizedBox(height: 8),
                  _AttachOption(
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
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
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

              return AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                                      : EagleTokens.line,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                      : EagleTokens.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child:
                                query.trim().isEmpty
                                    ? const _SearchState(
                                      icon: Icons.search_rounded,
                                      title: 'Digite para buscar',
                                      subtitle:
                                          'Encontre mensagens antigas da conversa.',
                                    )
                                    : searching
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : searched && results.isEmpty
                                    ? const _SearchState(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => SafeArea(
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
    );
  }

  void _showMediaGallerySheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    MediaType? selected;

    List<ChatMsg> filtered(MediaType? type) {
      return _msgs
          .where((msg) {
            final tipo = msg.primaryMediaType;
            final url = msg.primaryMediaUrl;
            if (tipo == null || url == null || url.isEmpty) return false;
            if (type == null) return true;
            return _mediaType(type) == tipo ||
                (type == MediaType.photo && tipo == 'IMAGEM');
          })
          .toList(growable: false)
          .reversed
          .toList(growable: false);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final items = filtered(selected);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
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
                                      : EagleTokens.line,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Midias da conversa',
                          style: TextStyle(
                            color:
                                isDark ? EagleTokens.darkInk : EagleTokens.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _MediaFilterChip(
                                label: 'Tudo',
                                selected: selected == null,
                                onTap:
                                    () => setSheetState(() => selected = null),
                                primary: primary,
                                isDark: isDark,
                              ),
                              _MediaFilterChip(
                                label: 'Fotos',
                                selected: selected == MediaType.photo,
                                onTap:
                                    () => setSheetState(
                                      () => selected = MediaType.photo,
                                    ),
                                primary: primary,
                                isDark: isDark,
                              ),
                              _MediaFilterChip(
                                label: 'Videos',
                                selected: selected == MediaType.video,
                                onTap:
                                    () => setSheetState(
                                      () => selected = MediaType.video,
                                    ),
                                primary: primary,
                                isDark: isDark,
                              ),
                              _MediaFilterChip(
                                label: 'Audios',
                                selected: selected == MediaType.audio,
                                onTap:
                                    () => setSheetState(
                                      () => selected = MediaType.audio,
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
                                  ? const _SearchState(
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
                                      return _MediaGalleryTile(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o anexo.')),
      );
    }
  }

  void _showImageViewer(String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? EagleTokens.darkCard
                                      : EagleTokens.card,
                              borderRadius: BorderRadius.circular(24),
                            ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final brand =
        _isAlunoMode ? ref.watch(personalBrandProvider).valueOrNull : null;
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
          onPressed:
              () => safePopOrGo(
                context,
                _isAlunoMode ? '/dashboard/aluno' : '/dashboard/personal',
              ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.18)),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: primarySoft,
                backgroundImage:
                    _avatarImage(brand) == null
                        ? null
                        : NetworkImage(_avatarImage(brand)!),
                child:
                    _avatarImage(brand) == null
                        ? Text(
                          fxInitials(title),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        )
                        : null,
              ),
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
                          isDark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showSearchSheet,
            icon: const Icon(Icons.search_rounded),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: _ChatBackdrop(isDark: isDark, accentColor: primary),
          ),
          Column(
            children: [
              if (_uploading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: primarySoft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Enviando anexo...',
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child:
                    _loading
                        ? Center(
                          child: CircularProgressIndicator(color: primary),
                        )
                        : _loadFailed
                        ? _ConversationErrorState(
                          isDark: isDark,
                          accentColor: primary,
                          onRetry: () {
                            setState(() {
                              _loading = true;
                              _loadFailed = false;
                            });
                            unawaited(_loadHistorico());
                          },
                        )
                        : _msgs.isEmpty
                        ? _EmptyConversation(
                          isDark: isDark,
                          accentColor: primary,
                          title: 'Comece uma conversa',
                          subtitle:
                              'Fotos, videos, audios e ajustes do treino vao aparecer aqui em tempo real.',
                        )
                        : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          itemCount:
                              _msgs.length +
                              (_hasMoreMessages || _loadingOlder ? 1 : 0) +
                              (_sending || _uploading ? 1 : 0),
                          itemBuilder: (_, index) {
                            final hasLoader = _hasMoreMessages || _loadingOlder;
                            if (hasLoader && index == 0) {
                              return _OlderMessagesLoader(
                                loading: _loadingOlder,
                                onTap: _loadOlderMessages,
                              );
                            }
                            final typingIndex =
                                _msgs.length + (hasLoader ? 1 : 0);
                            if ((_sending || _uploading) &&
                                index == typingIndex) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _TypingIndicator(
                                    isDark: isDark,
                                    accentColor: primary,
                                  ),
                                ),
                              );
                            }
                            final msgIndex = hasLoader ? index - 1 : index;
                            final msg = _msgs[msgIndex];
                            final previous =
                                msgIndex > 0 ? _msgs[msgIndex - 1] : null;
                            final showDate =
                                previous == null ||
                                !_sameDay(previous.enviadoEm, msg.enviadoEm);
                            return Column(
                              children: [
                                if (showDate) _DateDivider(date: msg.enviadoEm),
                                KeyedSubtree(
                                  key: _messageKey(msg),
                                  child: _SwipeReplyWrapper(
                                    alignRight: _isMine(msg),
                                    accentColor:
                                        _isMine(msg) ? Colors.white : primary,
                                    onReply: () => _setReply(msg),
                                    child: _Bubble(
                                      msg: msg,
                                      mine: _isMine(msg),
                                      isDark: isDark,
                                      accentColor: primary,
                                      highlighted:
                                          _highlightedMessageId == msg.id,
                                      replyLabelBuilder: _replySenderLabel,
                                      onLongPress:
                                          () => _showMessageActions(msg),
                                      onReplyTap:
                                          msg.replyToMessageId == null
                                              ? null
                                              : () => _jumpToReplySource(msg),
                                      onOpenMedia: () => _openMedia(msg),
                                    ),
                                  ),
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
                  color: (isDark ? EagleTokens.darkBg : EagleTokens.paper)
                      .withValues(alpha: 0.86),
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.05,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed:
                          (_sending || _uploading)
                              ? null
                              : _showAttachmentSheet,
                      icon: const Icon(Icons.add_circle),
                      color: EagleTokens.inkMute,
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? EagleTokens.darkCard
                                      : EagleTokens.card)
                                  .withValues(alpha: isDark ? 0.82 : 0.9),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color:
                                    isDark
                                        ? EagleTokens.darkLine
                                        : EagleTokens.line,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_replyingTo != null)
                                  _ReplyComposerBar(
                                    isDark: isDark,
                                    sender: _replySenderLabel(
                                      _replyingTo!.remetente,
                                    ),
                                    preview: _previewText(_replyingTo!),
                                    onClose:
                                        () =>
                                            setState(() => _replyingTo = null),
                                  ),
                                if (_recordingAudio)
                                  _RecordingComposerBar(
                                    isDark: isDark,
                                    duration: _formatDuration(_recordDuration),
                                    onCancel:
                                        () => _stopAudioRecording(send: false),
                                    onSend:
                                        () => _stopAudioRecording(send: true),
                                  ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _ctrl,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? EagleTokens.darkInk
                                                  : EagleTokens.ink,
                                          fontSize: 15,
                                        ),
                                        cursorColor: primary,
                                        decoration: InputDecoration(
                                          hintText: 'iMessage',
                                          hintStyle: TextStyle(
                                            color:
                                                isDark
                                                    ? EagleTokens.darkInkMute
                                                    : EagleTokens.inkMute,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
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
                                      icon: const Icon(Icons.auto_awesome),
                                      color: EagleTokens.inkMute,
                                    ),
                                    if (_composerHasText || _sending)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                          bottom: 6,
                                        ),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed:
                                                (_sending || _uploading)
                                                    ? null
                                                    : _sendText,
                                            icon:
                                                _sending
                                                    ? const SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child:
                                                          CircularProgressIndicator(
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
                                    if (!_composerHasText && !_sending)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                          bottom: 6,
                                        ),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color:
                                                _recordingAudio
                                                    ? const Color(0xFFE5484D)
                                                    : primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            tooltip:
                                                _recordingAudio
                                                    ? 'Enviar audio'
                                                    : 'Gravar audio',
                                            onPressed:
                                                (_uploading || _sending)
                                                    ? null
                                                    : _recordingAudio
                                                    ? () => _stopAudioRecording(
                                                      send: true,
                                                    )
                                                    : _startAudioRecording,
                                            icon: Icon(
                                              _recordingAudio
                                                  ? Icons.stop_rounded
                                                  : Icons.mic_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final primary = Theme.of(context).colorScheme.primary;
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
            Icon(icon, color: primary),
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
  final Color accentColor;
  final String title;
  final String subtitle;

  const _EmptyConversation({
    required this.isDark,
    required this.accentColor,
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
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: accentColor,
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

class _ConversationErrorState extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final VoidCallback onRetry;

  const _ConversationErrorState({
    required this.isDark,
    required this.accentColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final muted = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
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
                color: accentColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: accentColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Nao foi possivel carregar a conversa',
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Verifique a conexao e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(backgroundColor: accentColor),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(local.year, local.month, local.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final label =
        value == today
            ? 'Hoje'
            : value == yesterday
            ? 'Ontem'
            : '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : EagleTokens.inkMute,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OlderMessagesLoader extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _OlderMessagesLoader({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child:
                loading
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    )
                    : Text(
                      'Carregar mensagens antigas',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryStatus extends StatelessWidget {
  final ChatMsg msg;
  final Color color;

  const _DeliveryStatus({required this.msg, required this.color});

  @override
  Widget build(BuildContext context) {
    final read = msg.readAt != null;
    final delivered = msg.deliveredAt != null;
    final iconColor = read ? const Color(0xFF60A5FA) : color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          delivered ? Icons.done_all_rounded : Icons.check_rounded,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(width: 2),
        Text(
          read
              ? 'Lido'
              : delivered
              ? 'Entregue'
              : 'Enviado',
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  final Color accentColor;

  const _TypingIndicator({required this.isDark, required this.accentColor});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? EagleTokens.darkCardHi : EagleTokens.card;
    final border = widget.isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = ((_ctrl.value + (i / 3)) % 1.0);
              final opacity = t < 0.5 ? 0.3 + t * 1.4 : 1.0 - (t - 0.5) * 1.4;
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withValues(
                    alpha: opacity.clamp(0.3, 1.0),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _SwipeReplyWrapper extends StatefulWidget {
  final Widget child;
  final bool alignRight;
  final Color accentColor;
  final VoidCallback onReply;

  const _SwipeReplyWrapper({
    required this.child,
    required this.alignRight,
    required this.accentColor,
    required this.onReply,
  });

  @override
  State<_SwipeReplyWrapper> createState() => _SwipeReplyWrapperState();
}

class _SwipeReplyWrapperState extends State<_SwipeReplyWrapper> {
  double _offset = 0;
  bool _triggered = false;

  void _handleUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final next =
        widget.alignRight
            ? (_offset + delta).clamp(-54.0, 0.0)
            : (_offset + delta).clamp(0.0, 54.0);
    if (!_triggered && next.abs() >= 34) {
      _triggered = true;
      HapticFeedback.lightImpact();
      widget.onReply();
    }
    setState(() => _offset = next);
  }

  void _reset() {
    if (mounted) {
      setState(() => _offset = 0);
    }
    _triggered = false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.86,
      child: Stack(
        alignment:
            widget.alignRight ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Positioned(
            left: widget.alignRight ? null : 6,
            right: widget.alignRight ? 6 : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _offset.abs() > 8 ? 1 : 0,
              child: Icon(
                Icons.reply_rounded,
                color: widget.accentColor,
                size: 18,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _handleUpdate,
              onHorizontalDragEnd: (_) => _reset(),
              onHorizontalDragCancel: _reset,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBackdrop extends StatelessWidget {
  final bool isDark;
  final Color accentColor;

  const _ChatBackdrop({required this.isDark, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDark
                  ? const [
                    Color(0xFF09101F),
                    Color(0xFF0C1428),
                    Color(0xFF101B34),
                  ]
                  : const [
                    Color(0xFFF6F7FB),
                    Color(0xFFF8F8F6),
                    Color(0xFFF2F5FB),
                  ],
        ),
      ),
      child: CustomPaint(
        painter: _ChatBackdropPainter(isDark: isDark, accentColor: accentColor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChatBackdropPainter extends CustomPainter {
  final bool isDark;
  final Color accentColor;

  const _ChatBackdropPainter({required this.isDark, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = (isDark ? Colors.white : accentColor).withValues(
            alpha: isDark ? 0.028 : 0.04,
          )
          ..strokeWidth = 1;
    const gap = 26.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
  }
}

class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  final bool mine;
  final bool isDark;
  final Color accentColor;
  final bool highlighted;
  final String Function(String remetente) replyLabelBuilder;
  final VoidCallback onLongPress;
  final VoidCallback? onReplyTap;
  final VoidCallback onOpenMedia;

  const _Bubble({
    required this.msg,
    required this.mine,
    required this.isDark,
    required this.accentColor,
    required this.highlighted,
    required this.replyLabelBuilder,
    required this.onLongPress,
    required this.onReplyTap,
    required this.onOpenMedia,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        mine ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink);
    final metaColor =
        mine
            ? Colors.white.withValues(alpha: 0.75)
            : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute);
    final deleted = msg.deletedAt != null;
    final displayText = formatChatTextForDisplay(msg.conteudo);
    final bubbleMaxWidth = (MediaQuery.sizeOf(context).width - 56).clamp(
      220.0,
      520.0,
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
          decoration: BoxDecoration(
            gradient:
                mine
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor, BrandPalette.deep(accentColor)],
                    )
                    : null,
            color:
                mine
                    ? null
                    : (isDark ? EagleTokens.darkCardHi : EagleTokens.card),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            border: Border.all(
              color:
                  highlighted
                      ? accentColor
                      : mine
                      ? Colors.transparent
                      : (isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
              width: highlighted ? 1.6 : 1,
            ),
            boxShadow:
                highlighted
                    ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!deleted && msg.replyToMessageId != null)
                _ReplySnippet(
                  mine: mine,
                  isDark: isDark,
                  accentColor: accentColor,
                  sender: replyLabelBuilder(msg.replyToRemetente ?? ''),
                  preview:
                      msg.replyToConteudo?.trim().isNotEmpty == true
                          ? msg.replyToConteudo!.trim()
                          : 'Midia',
                  onTap: onReplyTap,
                ),
              if (!deleted)
                _MediaPreview(
                  msg: msg,
                  mine: mine,
                  isDark: isDark,
                  onOpen: onOpenMedia,
                ),
              if (deleted)
                Text(
                  'Mensagem apagada',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.72),
                    fontSize: 14,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (displayText.isNotEmpty &&
                  !_isMediaLabelOnly(msg.primaryMediaType, msg.conteudo))
                Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              if (msg.reactions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final reaction in msg.reactions)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              reaction.mine
                                  ? (mine
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : accentColor.withValues(alpha: 0.12))
                                  : (mine
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : (isDark
                                          ? EagleTokens.darkBg
                                          : EagleTokens.paper)),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                reaction.mine
                                    ? accentColor.withValues(alpha: 0.5)
                                    : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '${reaction.emoji} ${reaction.total}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight:
                                reaction.mine
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!deleted && msg.editedAt != null) ...[
                    Text(
                      'editada',
                      style: TextStyle(color: metaColor, fontSize: 11),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    _timeLabel(msg.enviadoEm),
                    style: TextStyle(color: metaColor, fontSize: 11),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 6),
                    _DeliveryStatus(msg: msg, color: metaColor),
                  ],
                ],
              ),
            ],
          ),
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
}

class _ReplySnippet extends StatelessWidget {
  final bool mine;
  final bool isDark;
  final Color accentColor;
  final String sender;
  final String preview;
  final VoidCallback? onTap;

  const _ReplySnippet({
    required this.mine,
    required this.isDark,
    required this.accentColor,
    required this.sender,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        mine ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              mine
                  ? Colors.white.withValues(alpha: 0.14)
                  : accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.88),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.82),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyComposerBar extends StatelessWidget {
  final bool isDark;
  final String sender;
  final String preview;
  final VoidCallback onClose;

  const _ReplyComposerBar({
    required this.isDark,
    required this.sender,
    required this.preview,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _SearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SearchState({
    required this.icon,
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
            Icon(icon, size: 30, color: EagleTokens.inkMute),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: EagleTokens.inkMute),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingComposerBar extends StatelessWidget {
  final bool isDark;
  final String duration;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _RecordingComposerBar({
    required this.isDark,
    required this.duration,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFE5484D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gravando $duration',
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancelar audio',
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            icon: Icon(Icons.delete_outline_rounded, color: mute),
          ),
          IconButton(
            tooltip: 'Enviar audio',
            visualDensity: VisualDensity.compact,
            onPressed: onSend,
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final ChatMsg msg;
  final bool mine;
  final bool isDark;
  final VoidCallback onOpen;

  const _MediaPreview({
    required this.msg,
    required this.mine,
    required this.isDark,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tipo = msg.primaryMediaType;
    final url = msg.primaryMediaUrl;
    if (tipo == null || url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    if (tipo == 'IMAGE' || tipo == 'IMAGEM') {
      final previewWidth = (MediaQuery.sizeOf(context).width * 0.56).clamp(
        156.0,
        220.0,
      );
      final previewHeight = previewWidth * 0.9;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: onOpen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.network(
                  url,
                  height: previewHeight,
                  width: previewWidth,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: previewHeight,
                        width: previewWidth,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Abrir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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

    if (tipo == 'AUDIO') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _AudioInlinePlayer(
          url: url,
          label: msg.conteudo.replaceFirst('Audio ', ''),
          mine: mine,
          isDark: isDark,
          onFallbackOpen: onOpen,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                mine
                    ? Colors.white.withValues(alpha: 0.12)
                    : primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toque para abrir',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.72),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: textColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final bool isDark;

  const _MediaFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink =
        selected
            ? Colors.white
            : (isDark ? EagleTokens.darkInk : EagleTokens.ink);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color:
                selected
                    ? primary
                    : (isDark ? EagleTokens.darkCardHi : EagleTokens.card),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? primary
                      : (isDark ? EagleTokens.darkLine : EagleTokens.line),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaGalleryTile extends StatelessWidget {
  final ChatMsg msg;
  final bool isDark;
  final VoidCallback onTap;

  const _MediaGalleryTile({
    required this.msg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = msg.primaryMediaType;
    final title = _title(tipo);
    final icon = _icon(tipo);
    final url = msg.primaryMediaUrl;
    final isImage = tipo == 'IMAGE';
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final muted = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.line,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 54,
                height: 54,
                color: primary.withValues(alpha: 0.10),
                child:
                    isImage && url != null && url.isNotEmpty
                        ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.broken_image_outlined,
                                color: primary,
                              ),
                        )
                        : Icon(icon, color: primary, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sender(msg.remetente)} - ${_dateLabel(msg.enviadoEm)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  static IconData _icon(String? tipo) {
    if (tipo == 'VIDEO') return Icons.play_circle_outline_rounded;
    if (tipo == 'AUDIO') return Icons.graphic_eq_rounded;
    return Icons.image_outlined;
  }

  static String _title(String? tipo) {
    if (tipo == 'VIDEO') return 'Video';
    if (tipo == 'AUDIO') return 'Audio';
    return 'Foto';
  }

  static String _sender(String remetente) {
    if (remetente == 'PERSONAL') return 'Personal';
    if (remetente == 'ALUNO') return 'Aluno';
    return remetente;
  }

  static String _dateLabel(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _AudioInlinePlayer extends StatefulWidget {
  final String url;
  final String label;
  final bool mine;
  final bool isDark;
  final VoidCallback onFallbackOpen;

  const _AudioInlinePlayer({
    required this.url,
    required this.label,
    required this.mine,
    required this.isDark,
    required this.onFallbackOpen,
  });

  @override
  State<_AudioInlinePlayer> createState() => _AudioInlinePlayerState();
}

class _AudioInlinePlayerState extends State<_AudioInlinePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_player.playing) {
      await _player.pause();
      return;
    }

    setState(() => _busy = true);
    try {
      if (!_loaded) {
        await _player.setUrl(widget.url);
        _loaded = true;
      }
      await _player.play();
    } catch (_) {
      widget.onFallbackOpen();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg =
        widget.mine
            ? Colors.white.withValues(alpha: 0.12)
            : primary.withValues(alpha: 0.10);
    final ink =
        widget.mine
            ? Colors.white
            : (widget.isDark ? EagleTokens.darkInk : EagleTokens.ink);
    final muted = ink.withValues(alpha: 0.70);
    final name = widget.label.trim().isEmpty ? 'Audio' : widget.label.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final processing =
                    snapshot.data?.processingState ?? ProcessingState.idle;
                final loading = _busy || processing == ProcessingState.loading;
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  tooltip: playing ? 'Pausar audio' : 'Reproduzir audio',
                  visualDensity: VisualDensity.compact,
                  onPressed: loading ? null : _toggle,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        widget.mine
                            ? Colors.white.withValues(alpha: 0.18)
                            : primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                  ),
                  icon:
                      loading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<Duration?>(
                stream: _player.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data;
                  return StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final totalMs = duration?.inMilliseconds ?? 0;
                      final progress =
                          totalMs <= 0
                              ? 0.0
                              : (position.inMilliseconds / totalMs).clamp(
                                0.0,
                                1.0,
                              );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              value: progress,
                              backgroundColor: ink.withValues(alpha: 0.16),
                              valueColor: AlwaysStoppedAnimation<Color>(ink),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_audioTime(position)} / ${_audioTime(duration)}',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Abrir anexo',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onFallbackOpen,
              icon: Icon(Icons.open_in_new_rounded, color: muted, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  static String _audioTime(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
