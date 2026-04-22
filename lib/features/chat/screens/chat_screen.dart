import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/theme/design_tokens.dart';
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

  static const _base = 'https://focux-backend.onrender.com';

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
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _connectWs() async {
    final token = await SecureStorage.getToken();
    final url = '${_base.replaceFirst('https', 'wss')}/ws/websocket';
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
        } catch (_) { _loadHistorico(); }
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
            child: Text(widget.alunoNome.isNotEmpty ? widget.alunoNome[0].toUpperCase() : '?', style: const TextStyle(color: EagleTokens.brand, fontWeight: FontWeight.w700, fontSize: 16)),
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
        // Input
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 8, 10 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkCard : EagleTokens.card,
            border: Border(top: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft)),
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 15),
              cursorColor: EagleTokens.brand,
              decoration: InputDecoration(
                hintText: 'Mensagem...',
                hintStyle: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
                filled: true,
                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 8),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: EagleTokens.brand, shape: BoxShape.circle, boxShadow: [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]),
              child: IconButton(
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _send,
              ),
            ),
          ]),
        ),
      ]),
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
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isPersonal ? EagleTokens.brand : (isDark ? EagleTokens.darkCardHi : EagleTokens.card),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isPersonal ? 18 : 4),
            bottomRight: Radius.circular(isPersonal ? 4 : 18),
          ),
          border: isPersonal ? null : Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (msg.midiaUrl != null && msg.tipoMidia == 'IMAGEM')
            Padding(padding: const EdgeInsets.only(bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(msg.midiaUrl!, fit: BoxFit.cover))),
          Text(msg.conteudo, style: TextStyle(color: isPersonal ? Colors.white : (isDark ? EagleTokens.darkInk : EagleTokens.ink), fontSize: 14.5)),
        ]),
      ),
    );
  }
}
