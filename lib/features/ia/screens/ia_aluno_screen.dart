import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/chat/data/chat_repository.dart';
import '../data/ia_repository.dart';

class IaAlunoScreen extends ConsumerStatefulWidget {
  const IaAlunoScreen({super.key});

  @override
  ConsumerState<IaAlunoScreen> createState() => _IaAlunoScreenState();
}

class _IaAlunoScreenState extends ConsumerState<IaAlunoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int? _alunoId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _resolverAlunoId();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _resolverAlunoId() async {
    try {
      final msgs = await ChatRepository(ref.read(apiClientProvider)).historicoAluno();
      final id = msgs.isNotEmpty ? msgs.first.alunoId : null;
      if (id != null && mounted) setState(() => _alunoId = id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      title: const Text('Assistente IA'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(icon: Icon(Icons.chat), text: 'Chat'),
          Tab(icon: Icon(Icons.trending_up), text: 'Progressão'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        _ChatTab(alunoId: _alunoId),
        _ProgressaoTab(alunoId: _alunoId),
      ],
    ),
  );
}

// ─── Chat Tab ─────────────────────────────────────────────────────────────────

class _IaMsg {
  final String texto;
  final bool isUser;
  _IaMsg({required this.texto, required this.isUser});
}

class _ChatTab extends ConsumerStatefulWidget {
  final int? alunoId;
  const _ChatTab({this.alunoId});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final List<_IaMsg> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_IaMsg(texto: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final resposta = await repo.chat(text, alunoId: widget.alunoId);
      if (mounted) setState(() => _msgs.add(_IaMsg(texto: resposta, isUser: false)));
    } catch (e) {
      if (mounted) setState(() => _msgs.add(_IaMsg(texto: 'Erro: $e', isUser: false)));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(
      child: _msgs.isEmpty
          ? const Center(child: Text('Pergunte sobre treino, dieta ou saúde!'))
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _msgs.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _msgs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final m = _msgs[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.texto,
                        style: TextStyle(color: m.isUser ? Colors.white : null)),
                  ),
                );
              },
            ),
    ),
    const Divider(height: 1),
    Padding(
      padding: EdgeInsets.only(
        left: 12, right: 8, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            hintText: 'Pergunte ao assistente...',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _enviar(),
        )),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.send),
          onPressed: _loading ? null : _enviar,
        ),
      ]),
    ),
  ]);
}

// ─── Progressão Tab ───────────────────────────────────────────────────────────

class _ProgressaoTab extends ConsumerStatefulWidget {
  final int? alunoId;
  const _ProgressaoTab({this.alunoId});

  @override
  ConsumerState<_ProgressaoTab> createState() => _ProgressaoTabState();
}

class _ProgressaoTabState extends ConsumerState<_ProgressaoTab> {
  bool _loading = false;
  String? _resultado;

  Future<void> _gerarProgressao() async {
    setState(() { _loading = true; _resultado = null; });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final id = widget.alunoId ?? 0;
      final r = await repo.progressaoCarga(id);
      if (mounted) setState(() => _resultado = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text(
        'Progressão de Carga',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Gere recomendações personalizadas de progressão de carga com base no seu histórico de treinos.',
        style: TextStyle(color: EagleTokens.inkMute),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _loading ? null : _gerarProgressao,
        icon: _loading
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome),
        label: Text(_loading ? 'Analisando...' : 'Gerar Recomendações'),
      ),
      if (_resultado != null) ...[
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        MarkdownBody(data: _resultado!, selectable: true),
      ],
    ]),
  );
}
