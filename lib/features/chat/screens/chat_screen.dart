import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
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

  static const _base = 'https://focux-backend.up.railway.app';

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

    _stomp = StompClient(
      config: StompConfig(
        url: url,
        onConnect: _onConnect,
        beforeConnect: () async {},
        onStompError: (_) {},
        onDisconnect: (_) {},
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
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
          if (mounted) {
            setState(() => _msgs.add(msg));
            _scrollToBottom();
          }
        } catch (_) {
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

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      final msg = await ChatRepository(ref.read(apiClientProvider))
          .enviar(widget.alunoId, text, 'PERSONAL');
      setState(() => _msgs.add(msg));
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Chat — ${widget.alunoNome}')),
    body: Column(children: [
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _msgs.isEmpty
                ? const Center(child: Text('Nenhuma mensagem ainda.'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) => _Bubble(msg: _msgs[i]),
                  ),
      ),
      const Divider(height: 1),
      Padding(
        padding: EdgeInsets.only(
            left: 12, right: 8, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _ctrl,
            decoration: const InputDecoration(hintText: 'Mensagem...', border: OutlineInputBorder()),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: _sending
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            onPressed: _send,
          ),
        ]),
      ),
    ]),
  );
}

class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  const _Bubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    final isPersonal = msg.remetente == 'PERSONAL';
    return Align(
      alignment: isPersonal ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isPersonal
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isPersonal ? 16 : 4),
            bottomRight: Radius.circular(isPersonal ? 4 : 16),
          ),
        ),
        child: Text(
          msg.conteudo,
          style: TextStyle(color: isPersonal ? Colors.white : null),
        ),
      ),
    );
  }
}
