import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';

class ChatAlunoScreen extends ConsumerStatefulWidget {
  const ChatAlunoScreen({super.key});

  @override
  ConsumerState<ChatAlunoScreen> createState() => _ChatAlunoScreenState();
}

class _ChatAlunoScreenState extends ConsumerState<ChatAlunoScreen> {
  final List<ChatMsg> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  StompClient? _stomp;
  bool _loading = true;
  bool _sending = false;
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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectWs(int alunoId) async {
    final token = await SecureStorage.getToken();
    final url = '${_base.replaceFirst('https', 'wss')}/ws/websocket';

    _stomp = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (frame) => _onConnect(frame, alunoId),
        beforeConnect: () async {},
        onStompError: (_) {},
        onDisconnect: (_) {},
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
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
      final msg = await ChatRepository(ref.read(apiClientProvider)).enviarComoAluno(text);
      // Se ainda não temos o alunoId, pegar da resposta e conectar WS
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat com Personal')),
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
                    itemBuilder: (_, i) => _BubbleAluno(msg: _msgs[i]),
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
            decoration: const InputDecoration(
              hintText: 'Mensagem...',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: _sending
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            onPressed: _sending ? null : _send,
          ),
        ]),
      ),
    ]),
  );
}

class _BubbleAluno extends StatelessWidget {
  final ChatMsg msg;
  const _BubbleAluno({required this.msg});

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
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAluno ? 16 : 4),
            bottomRight: Radius.circular(isAluno ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.midiaUrl != null && msg.tipoMidia == 'IMAGEM')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(msg.midiaUrl!, fit: BoxFit.cover),
                ),
              ),
            Text(
              msg.conteudo,
              style: TextStyle(color: isAluno ? Colors.white : null),
            ),
          ]
        ),
      ),
    );
  }
}
