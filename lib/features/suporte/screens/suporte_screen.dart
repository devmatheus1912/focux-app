import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/suporte_repository.dart';

const _severidades = ['BAIXA', 'MEDIA', 'ALTA', 'CRITICA'];

const _severidadeColors = {
  'BAIXA': Colors.green,
  'MEDIA': Colors.orange,
  'ALTA': Colors.deepOrange,
  'CRITICA': Colors.red,
};

const _statusColors = {
  'ABERTO': Colors.orange,
  'EM_ANALISE': Colors.blue,
  'RESOLVIDO': Colors.green,
};

class SuporteScreen extends ConsumerStatefulWidget {
  const SuporteScreen({super.key});

  @override
  ConsumerState<SuporteScreen> createState() => _SuporteScreenState();
}

class _SuporteScreenState extends ConsumerState<SuporteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Suporte'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Abrir Ticket'),
              Tab(icon: Icon(Icons.list_alt), text: 'Meus Tickets'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _AbrirTicketTab(),
            _MeusTicketsTab(),
          ],
        ),
      );
}

// --------------------------------------------------------------------------
// Tab 1 — Abrir Ticket
// --------------------------------------------------------------------------

class _AbrirTicketTab extends ConsumerStatefulWidget {
  const _AbrirTicketTab();

  @override
  ConsumerState<_AbrirTicketTab> createState() => _AbrirTicketTabState();
}

class _ChatMessage {
  final String texto;
  final bool isUser;
  _ChatMessage({required this.texto, required this.isUser});
}

class _AbrirTicketTabState extends ConsumerState<_AbrirTicketTab> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _classeCtrl = TextEditingController();
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _severidade = 'MEDIA';
  bool _enviando = false;
  bool _enviandoChat = false;

  SuporteTicket? _ticketCriado;
  final List<_ChatMessage> _mensagens = [];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _classeCtrl.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final repo = SuporteRepository(ref.read(apiClientProvider));
      final ticket = await repo.criarTicket(
        titulo: _tituloCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        severidade: _severidade,
        classeAfetada: _classeCtrl.text.trim().isEmpty ? null : _classeCtrl.text.trim(),
      );
      setState(() {
        _ticketCriado = ticket;
        _enviando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket criado com sucesso!')),
        );
      }
      // Primeira mensagem automática da IA
      await _enviarMensagemIA(_descricaoCtrl.text.trim(), ticketId: ticket.id, autoMsg: true);
    } catch (e) {
      setState(() => _enviando = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _enviarMensagemIA(String mensagem,
      {int? ticketId, bool autoMsg = false}) async {
    if (!autoMsg) {
      setState(() {
        _mensagens.add(_ChatMessage(texto: mensagem, isUser: true));
        _chatCtrl.clear();
      });
    }
    setState(() => _enviandoChat = true);
    _scrollToBottom();
    try {
      final repo = SuporteRepository(ref.read(apiClientProvider));
      final resposta = await repo.chat(
        mensagem,
        ticketId: ticketId ?? _ticketCriado?.id,
      );
      setState(() {
        _mensagens.add(_ChatMessage(texto: resposta, isUser: false));
        _enviandoChat = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _enviandoChat = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro no chat: $e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviarChat() {
    final texto = _chatCtrl.text.trim();
    if (texto.isEmpty) return;
    _enviarMensagemIA(texto);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Formulário — só exibido antes de criar o ticket
          if (_ticketCriado == null) ...[
            Text('Novo Ticket de Suporte',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe um título' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Descreva o problema' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _severidade,
                  decoration: const InputDecoration(
                    labelText: 'Severidade *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.warning_amber),
                  ),
                  items: _severidades
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Row(children: [
                              Icon(Icons.circle,
                                  size: 10,
                                  color: _severidadeColors[s] ?? Colors.grey),
                              const SizedBox(width: 8),
                              Text(s),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _severidade = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _classeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Classe Afetada (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                    hintText: 'Ex: TreinoService',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _enviando ? null : _enviarTicket,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Enviar Ticket'),
                ),
              ]),
            ),
          ],

          // Chat IA — exibido após criar o ticket
          if (_ticketCriado != null) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ticket #${_ticketCriado!.id} criado',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_ticketCriado!.titulo,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Text('Assistente IA',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Lista de mensagens
            Container(
              constraints: const BoxConstraints(minHeight: 200),
              child: Column(
                children: [
                  ..._mensagens.map((m) => _BubbleMensagem(msg: m)),
                  if (_enviandoChat)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: _TypingIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Input do chat
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviandoChat ? null : _enviarChat(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _enviandoChat ? null : _enviarChat,
                icon: const Icon(Icons.send),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _BubbleMensagem extends StatelessWidget {
  final _ChatMessage msg;
  const _BubbleMensagem({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.texto,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('IA digitando...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
}

// --------------------------------------------------------------------------
// Tab 2 — Meus Tickets
// --------------------------------------------------------------------------

class _MeusTicketsTab extends ConsumerStatefulWidget {
  const _MeusTicketsTab();

  @override
  ConsumerState<_MeusTicketsTab> createState() => _MeusTicketsTabState();
}

class _MeusTicketsTabState extends ConsumerState<_MeusTicketsTab> {
  List<SuporteTicket> _tickets = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final repo = SuporteRepository(ref.read(apiClientProvider));
      final tickets = await repo.meusTickets();
      if (mounted) setState(() { _tickets = tickets; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Erro ao carregar tickets', style: TextStyle(color: Colors.red[700])),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _load, child: const Text('Tentar novamente')),
        ]),
      );
    }
    if (_tickets.isEmpty) {
      return const Center(child: Text('Nenhum ticket aberto.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: _tickets.length,
        itemBuilder: (_, i) => _TicketCard(ticket: _tickets[i]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SuporteTicket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[ticket.status] ?? Colors.grey;
    final sevColor = _severidadeColors[ticket.severidade] ?? Colors.grey;
    final resolvido = ticket.status == 'RESOLVIDO';
    final temResposta = resolvido && ticket.respostaAdmin != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: temResposta
          ? ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: _TicketTileContent(ticket: ticket, statusColor: statusColor, sevColor: sevColor),
              children: [
                const Divider(),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.support_agent, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Resposta do Suporte',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(ticket.respostaAdmin!,
                          style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                ]),
              ],
            )
          : ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: _TicketTileContent(ticket: ticket, statusColor: statusColor, sevColor: sevColor),
            ),
    );
  }
}

class _TicketTileContent extends StatelessWidget {
  final SuporteTicket ticket;
  final Color statusColor;
  final Color sevColor;
  const _TicketTileContent({
    required this.ticket,
    required this.statusColor,
    required this.sevColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(ticket.titulo,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(ticket.severidade,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: sevColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: sevColor),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 6),
        Chip(
          label: Text(ticket.status,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: statusColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: statusColor),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ]),
      if (ticket.criadoEm != null) ...[
        const SizedBox(height: 4),
        Text(
          'Aberto em ${ticket.criadoEm!.length >= 10 ? ticket.criadoEm!.substring(0, 10) : ticket.criadoEm!}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    ]);
  }
}
