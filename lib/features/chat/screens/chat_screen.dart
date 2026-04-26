import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const ChatScreen({super.key, required this.alunoId, required this.alunoNome});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMsg> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  StompClient? _stomp;
  bool _loading = true;
  bool _sending = false;


  @override
  void initState() {
    super.initState();
    _loadHistorico();
    _connectWs();
  }

  Future<void> _loadHistorico() async {
    try {
      final msgs = await ChatRepository(ref.read(apiClientProvider)).historico(widget.alunoId);
      setState(() { _msgs.addAll(msgs); _loading = false; });
      _scrollToBottom();
    } catch (e) { debugPrint('[Focux] Error: $e'); setState(() => _loading = false); }
  }

  Future<void> _connectWs() async {
    final token = await SecureStorage.getToken();
    final url = '${Env.wsUrl}/ws/websocket';
    _stomp = StompClient(config: StompConfig(
      url: url, onConnect: _onConnect, beforeConnect: () async {},
      onStompError: (_) {}, onDisconnect: (_) {},
      stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
      webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));
    _stomp!.activate();
  }

  void _onConnect(StompFrame frame) {
    _stomp?.subscribe(
      destination: '/topic/chat.${widget.alunoId}',
      callback: (f) {
        if (f.body == null) return;
        try {
          final data = jsonDecode(f.body!) as Map<String, dynamic>;
          final msg = ChatMsg.fromJson(data);
          if (mounted) { setState(() => _msgs.add(msg)); _scrollToBottom(); }
        } catch (e) { debugPrint('[Focux] Error: $e'); _loadHistorico(); }
      },
    );
  }

  @override
  void dispose() { _stomp?.deactivate(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      final msg = await ChatRepository(ref.read(apiClientProvider)).enviar(widget.alunoId, text, 'PERSONAL');
      setState(() => _msgs.add(msg));
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: isDark ? EagleTokens.darkInk : EagleTokens.ink), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: EagleTokens.brand.withValues(alpha: 0.12),
            child: Text(fxInitials(widget.alunoNome), style: const TextStyle(color: EagleTokens.brand, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.alunoNome, style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 16, fontWeight: FontWeight.w600)),
            Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: EagleTokens.good, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('Online', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 11)),
            ]),
          ]),
        ]),
        actions: [
          // IA button
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EagleTokens.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: EagleTokens.brand),
                  SizedBox(width: 4),
                  Text('IA', style: TextStyle(color: EagleTokens.brand, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: isDark ? EagleTokens.darkInk : EagleTokens.ink, size: 22),
            onPressed: _showChatMenu,
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft)),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: EagleTokens.brand))
              : _msgs.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 56, height: 56, decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.chat_outlined, color: EagleTokens.brand, size: 28)),
                      const SizedBox(height: 12),
                      Text('Comece uma conversa', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 15)),
                    ]))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: _msgs.length,
                      itemBuilder: (_, i) => _Bubble(msg: _msgs[i], isDark: isDark),
                    ),
        ),
        // Input (iMessage style)
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
                onPressed: _showAttachMenu,
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
                              icon: _sending
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                              onPressed: _send,
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

  void _showChatMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline, color: EagleTokens.brand),
              title: const Text('Ver perfil do aluno'),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.of(context).pushNamed('/alunos/${widget.alunoId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: EagleTokens.brand),
              title: const Text('Buscar na conversa'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Busca na conversa em breve.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined, color: EagleTokens.warn),
              title: const Text('Silenciar notificações'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificações silenciadas.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: EagleTokens.brand),
              title: const Text('Enviar foto da galeria'),
              subtitle: const Text('Upload via Cloudinary (em breve)'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anexo de imagem em breve.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: EagleTokens.brand),
              title: const Text('Compartilhar treino'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compartilhamento em breve.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available_outlined, color: EagleTokens.brand),
              title: const Text('Agendar treino'),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.of(context).pushNamed('/agenda');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  final bool isDark;
  const _Bubble({required this.msg, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final isPersonal = msg.remetente == 'PERSONAL';
    return Align(
      alignment: isPersonal ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          // Design spec: personal bubbles use gradient 135° brand→brandInk
          gradient: isPersonal
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [EagleTokens.brand, EagleTokens.brandInk],
                )
              : null,
          color: isPersonal ? null : (isDark ? EagleTokens.darkCardHi : EagleTokens.card),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isPersonal ? 20 : 6),
            bottomRight: Radius.circular(isPersonal ? 6 : 20),
          ),
          border: isPersonal ? null : Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (msg.midiaUrl != null && msg.tipoMidia == 'IMAGEM')
            Padding(padding: const EdgeInsets.only(bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(msg.midiaUrl!, fit: BoxFit.cover))),
          Text(msg.conteudo, style: TextStyle(color: isPersonal ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink), fontSize: 15, height: 1.3)),
        ]),
      ),
    );
  }
}

