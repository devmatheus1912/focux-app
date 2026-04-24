import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';

// ─── Cloudinary config ───────────────────────────────────────────────────────
const _kCloudName    = 'focux';
const _kUploadPreset = 'focux_unsigned';
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

  static const _base = 'https://focux-backend.onrender.com';

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
      if (mounted) setState(() { _msgs.addAll(msgs); _loading = false; });
      _scrollToBottom();
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectWs(int alunoId) async {
    final token = await SecureStorage.getToken();
    final url   = '${_base.replaceFirst('https', 'wss')}/ws/websocket';

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
            setState(() => _msgs.add(msg));
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
      if (mounted) setState(() => _msgs.add(msg));
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
      if (mounted) setState(() => _msgs.add(msg));
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
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_kCloudName/auto/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _kUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body     = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary ${streamed.statusCode}: $body');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
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
        Padding(
          padding: EdgeInsets.only(
            left: 12, right: 8, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Row(children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: EagleTokens.brand,
              tooltip: 'Anexar mídia',
              onPressed: (_uploading || _sending) ? null : _showAttachmentSheet,
            ),
            const SizedBox(width: 4),
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Mensagem...',
                filled: true,
                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 8),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: EagleTokens.brand,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: EagleTokens.brand.withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3),
                )],
              ),
              child: IconButton(
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: (_sending || _uploading) ? null : _send,
              ),
            ),
          ]),
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAluno
              ? EagleTokens.brand
              : (isDark ? EagleTokens.darkCardHi : EagleTokens.card),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isAluno ? 16 : 4),
            bottomRight: Radius.circular(isAluno ? 4 : 16),
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
