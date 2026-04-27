import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/config/env.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';

// ─── Cloudinary config ───────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class ChatAlunoScreen extends ConsumerStatefulWidget {
  const ChatAlunoScreen({super.key});

  @override
  ConsumerState<ChatAlunoScreen> createState() => _ChatAlunoScreenState();
}

class _ChatAlunoScreenState extends ConsumerState<ChatAlunoScreen> {
  final List<ChatMsg> _msgs = [];
  final _ctrl    = TextEditingController();
  final _scroll  = ScrollController();
  final _picker  = ImagePicker();
  StompClient? _stomp;
  bool _loading       = true;
  bool _sending       = false;
  bool _uploading     = false;
  int? _alunoId;


  @override
  void initState() {
    super.initState();
    _loadHistorico();
  }

  Future<void> _loadHistorico() async {
    try {
      final msgs = await ChatRepository(ref.read(apiClientProvider)).historicoAluno();
      if (msgs.isNotEmpty && _alunoId == null) {
        final id = msgs.first.alunoId;
        if (id != null) {
          _alunoId = id;
          _connectWs(id);
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
      _scrollToBottom();
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectWs(int alunoId) async {
    final token = await SecureStorage.getToken();
    final url   = '${Env.wsUrl}/ws/websocket';

    _stomp = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (frame) => _onConnect(frame, alunoId),
        beforeConnect: () async {},
        onStompError: (_) {},
        onDisconnect: (_) {},
        stompConnectHeaders:    token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
    _stomp!.activate();
  }

  void _onConnect(StompFrame frame, int alunoId) {
    _stomp?.subscribe(
      destination: '/topic/chat.$alunoId',
      callback: (f) {
        if (f.body == null) return;
        try {
          final data = jsonDecode(f.body!) as Map<String, dynamic>;
          final msg  = ChatMsg.fromJson(data);
          if (mounted) {
            setState(() => _upsertMessage(msg));
            _scrollToBottom();
          }
        } catch (e) {
          debugPrint('[Focux] Error: $e');
          _loadHistorico();
        }
      },
    );
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Text send ──────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      final msg = await ChatRepository(ref.read(apiClientProvider)).enviarComoAluno(text);
      if (_alunoId == null && msg.alunoId != null) {
        _alunoId = msg.alunoId;
        _connectWs(msg.alunoId!);
      }
      if (mounted) setState(() => _upsertMessage(msg));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  // ── Media attachment ───────────────────────────────────────────────────────

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _AttachOption(
                icon: Icons.photo_camera_outlined,
                label: 'Foto',
                isDark: isDark,
                onTap: () { Navigator.pop(context); _pickAndSend(MediaType.foto); },
              ),
              const SizedBox(height: 8),
              _AttachOption(
                icon: Icons.videocam_outlined,
                label: 'Vídeo',
                isDark: isDark,
                onTap: () { Navigator.pop(context); _pickAndSend(MediaType.video); },
              ),
              const SizedBox(height: 8),
              _AttachOption(
                icon: Icons.mic_outlined,
                label: 'Áudio',
                isDark: isDark,
                onTap: () { Navigator.pop(context); _pickAndSend(MediaType.audio); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSend(MediaType type) async {
    XFile? file;
    try {
      if (type == MediaType.foto) {
        file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      } else if (type == MediaType.video) {
        file = await _picker.pickVideo(source: ImageSource.gallery);
      } else {
        // Áudio: use image picker's media (picks from gallery; for audio
        // we fall back to a generic file dialog via pickMedia).
        file = await _picker.pickMedia();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível selecionar o arquivo: $e')),
        );
      }
      return;
    }

    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final url = await _uploadToCloudinary(file, type);
      final tipoMidia = _tipoMidiaString(type);
      final conteudo  = _conteudoLabel(type);

      final msg = await ChatRepository(ref.read(apiClientProvider))
          .enviarMidiaComoAluno(
            conteudo: conteudo,
            tipoMidia: tipoMidia,
            midiaUrl: url,
          );

      if (_alunoId == null && msg.alunoId != null) {
        _alunoId = msg.alunoId;
        _connectWs(msg.alunoId!);
      }
      if (mounted) setState(() => _upsertMessage(msg));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mídia: $e')),
        );
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<String> _uploadToCloudinary(XFile file, MediaType type) async {
    return MediaUploadService(ref.read(apiClientProvider)).uploadBytes(
      bytes: await file.readAsBytes(),
      filename: file.name,
      folder: 'chat',
      resourceType: type == MediaType.foto ? 'image' : 'auto',
    );
  }

  String _tipoMidiaString(MediaType type) {
    switch (type) {
      case MediaType.foto:  return 'IMAGE';
      case MediaType.video: return 'VIDEO';
      case MediaType.audio: return 'AUDIO';
    }
  }

  String _conteudoLabel(MediaType type) {
    switch (type) {
      case MediaType.foto:  return '📷 Foto';
      case MediaType.video: return '🎬 Vídeo';
      case MediaType.audio: return '🎵 Áudio';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _upsertMessage(ChatMsg msg) {
    final id = msg.id;
    if (id != null) {
      final idx = _msgs.indexWhere((m) => m.id == id);
      if (idx >= 0) {
        _msgs[idx] = msg;
        return;
      }
    }
    _msgs.add(msg);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(title: const Text('Chat com Personal')),
      body: Column(children: [
        // Upload progress banner
        if (_uploading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: EagleTokens.brand.withValues(alpha: 0.12),
            child: Row(children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: EagleTokens.brand),
              ),
              const SizedBox(width: 10),
              Text(
                'Enviando mídia...',
                style: TextStyle(
                  color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                  fontSize: 13,
                ),
              ),
            ]),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: EagleTokens.brand))
              : _msgs.isEmpty
                  ? const Center(child: Text('Nenhuma mensagem ainda.'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: _msgs.length,
                      itemBuilder: (_, i) => _BubbleAluno(msg: _msgs[i], isDark: isDark),
                    ),
        ),
        const Divider(height: 1),
        // Input
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkBg : EagleTokens.paper,
            border: Border(top: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: EagleTokens.inkMute,
                iconSize: 26,
                padding: const EdgeInsets.only(bottom: 6),
                tooltip: 'Anexar mídia',
                onPressed: (_uploading || _sending) ? null : _showAttachmentSheet,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark ? Border.all(color: EagleTokens.darkLine) : Border.all(color: EagleTokens.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 15),
                          cursorColor: EagleTokens.brand,
                          decoration: InputDecoration(
                            hintText: 'iMessage',
                            hintStyle: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: InputBorder.none,
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      if (_ctrl.text.isNotEmpty || _sending)
                        Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 6),
                          child: Container(
                            width: 30, height: 30,
                            decoration: const BoxDecoration(color: EagleTokens.brand, shape: BoxShape.circle),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: _sending || _uploading
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                              onPressed: (_sending || _uploading) ? null : _send,
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
      ]),
    );
  }
}

// ── Media type enum ────────────────────────────────────────────────────────────

enum MediaType { foto, video, audio }

// ── Attachment option row ─────────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isDark;
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: EagleTokens.brand.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: EagleTokens.brand, size: 22),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Bubble ─────────────────────────────────────────────────────────────────────

class _BubbleAluno extends StatelessWidget {
  final ChatMsg msg;
  final bool    isDark;
  const _BubbleAluno({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAluno = msg.remetente == 'ALUNO';
    return Align(
      alignment: isAluno ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAluno
              ? EagleTokens.brand
              : (isDark ? EagleTokens.darkCardHi : EagleTokens.card),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(20),
            topRight:    const Radius.circular(20),
            bottomLeft:  Radius.circular(isAluno ? 20 : 6),
            bottomRight: Radius.circular(isAluno ? 6 : 20),
          ),
          border: isAluno
              ? null
              : Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MediaContent(msg: msg, isAluno: isAluno, isDark: isDark),
            if (msg.conteudo.isNotEmpty &&
                msg.tipoMidia != 'IMAGE' &&
                msg.tipoMidia != 'VIDEO' &&
                msg.tipoMidia != 'AUDIO')
              Text(
                msg.conteudo,
                style: TextStyle(
                  color: isAluno ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink),
                  fontSize: 14.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Media content renderer ─────────────────────────────────────────────────────

class _MediaContent extends StatelessWidget {
  final ChatMsg msg;
  final bool    isAluno;
  final bool    isDark;

  const _MediaContent({required this.msg, required this.isAluno, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final url       = msg.midiaUrl;
    final tipo      = msg.tipoMidia;
    final textColor = isAluno ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink);

    if (url == null || tipo == null) {
      return Text(
        msg.conteudo,
        style: TextStyle(color: textColor, fontSize: 14.5),
      );
    }

    // Backwards-compat: existing records may use 'IMAGEM'
    if (tipo == 'IMAGE' || tipo == 'IMAGEM') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        color: EagleTokens.brand,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
            errorBuilder: (_, __, ___) => Container(
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Icon(Icons.broken_image_outlined, color: EagleTokens.brand)),
            ),
          ),
        ),
      );
    }

    if (tipo == 'VIDEO') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: EagleTokens.brand.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.play_circle_outline, color: EagleTokens.brand, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vídeo',
                style: TextStyle(
                  color: isAluno ? Colors.white : EagleTokens.brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ]),
        ),
      );
    }

    if (tipo == 'AUDIO') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: EagleTokens.brand.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.audiotrack_outlined, color: EagleTokens.brand, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Áudio',
                style: TextStyle(
                  color: isAluno ? Colors.white : EagleTokens.brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ]),
        ),
      );
    }

    // Fallback: plain text
    return Text(msg.conteudo, style: TextStyle(color: textColor, fontSize: 14.5));
  }
}
