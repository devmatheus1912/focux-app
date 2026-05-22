import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_logo.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/suporte_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

const _severidades = ['BAIXA', 'MEDIA', 'ALTA', 'CRITICA'];

const _severidadeColors = {
  'BAIXA': EagleTokens.good,
  'MEDIA': EagleTokens.warn,
  'ALTA': EagleTokens.warn,
  'CRITICA': EagleTokens.bad,
};

const _statusColors = {
  'ABERTO': EagleTokens.warn,
  'RESOLVIDO': EagleTokens.good,
};

Color _statusColor(BuildContext context, String status) {
  return _statusColors[status] ?? Theme.of(context).colorScheme.primary;
}

class SuporteScreen extends ConsumerStatefulWidget {
  const SuporteScreen({super.key});

  @override
  ConsumerState<SuporteScreen> createState() => _SuporteScreenState();
}

class _ChatMessage {
  final String texto;
  final bool isUser;
  final bool isError;

  const _ChatMessage({
    required this.texto,
    required this.isUser,
    this.isError = false,
  });
}

class _SuporteScreenState extends ConsumerState<SuporteScreen> {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_ChatMessage> _mensagens =
      const [
        _ChatMessage(
          texto:
              'Oi! Sou a Central Ajuda. Me conte o que aconteceu ou escolha um atalho abaixo.',
          isUser: false,
        ),
      ].toList();

  bool _enviandoChat = false;
  SuporteTicket? _ticketCriado;

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarMensagem([String? textoPronto]) async {
    final texto = (textoPronto ?? _chatCtrl.text).trim();
    if (texto.isEmpty || _enviandoChat) return;

    setState(() {
      _mensagens.add(_ChatMessage(texto: texto, isUser: true));
      _chatCtrl.clear();
      _enviandoChat = true;
    });
    _scrollToBottom();

    try {
      final repo = SuporteRepository(ref.read(apiClientProvider));
      final resposta = await repo.chat(texto, ticketId: _ticketCriado?.id);
      if (!mounted) return;
      setState(() {
        _mensagens.add(_ChatMessage(texto: resposta, isUser: false));
        _enviandoChat = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagens.add(
          const _ChatMessage(
            texto:
                'Nao consegui enviar agora. Tente novamente em instantes ou abra um ticket.',
            isUser: false,
            isError: true,
          ),
        );
        _enviandoChat = false;
      });
      FeedbackHelper.showSuccess(context, 'Erro no chat: $e');
      _scrollToBottom();
    }
  }

  Future<void> _abrirTicketSheet() async {
    final ticket = await showModalBottomSheet<SuporteTicket>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NovoTicketSheet(),
    );
    if (ticket == null || !mounted) return;
    setState(() {
      _ticketCriado = ticket;
      _mensagens.add(
        _ChatMessage(
          texto:
              'Ticket #${ticket.id} criado e vinculado a esta conversa. Pode continuar por aqui.',
          isUser: false,
        ),
      );
    });
    FeedbackHelper.showSnackBar(
      context,
      SnackBar(content: Text('Ticket #${ticket.id} criado com sucesso.')),
    );
    _scrollToBottom();
  }

  void _abrirTicketsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => const FractionallySizedBox(
            heightFactor: 0.82,
            child: _MeusTicketsTab(),
          ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _SupportHeader(
              ticket: _ticketCriado,
              onTicketsTap: _abrirTicketsSheet,
            ),
            _QuickActions(
              onPromptTap: _enviarMensagem,
              onOpenTicketTap: _abrirTicketSheet,
              onTicketsTap: _abrirTicketsSheet,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                itemCount: _mensagens.length + (_enviandoChat ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _mensagens.length) {
                    return const _TypingIndicator();
                  }
                  return _BubbleMensagem(msg: _mensagens[index]);
                },
              ),
            ),
            _ChatComposer(
              controller: _chatCtrl,
              sending: _enviandoChat,
              onSend: () => _enviarMensagem(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportHeader extends StatelessWidget {
  final SuporteTicket? ticket;
  final VoidCallback onTicketsTap;

  const _SupportHeader({required this.ticket, required this.onTicketsTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primary,
                child: const FxLogoIcon(size: 34),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: EagleTokens.good,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suporte Focux',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'online · resposta imediata',
                      style: TextStyle(
                        color: EagleTokens.good,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (ticket != null) ...[
                      Text(
                        '  /  Ticket #${ticket!.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EagleTokens.inkMute,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTicketsTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Central de Ajuda',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ValueChanged<String> onPromptTap;
  final VoidCallback onOpenTicketTap;
  final VoidCallback onTicketsTap;

  const _QuickActions({
    required this.onPromptTap,
    required this.onOpenTicketTap,
    required this.onTicketsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickChip(
            icon: Icons.fitness_center_rounded,
            label: 'Treino',
            onTap: () => onPromptTap('Estou com problema em um treino.'),
          ),
          _QuickChip(
            icon: Icons.payments_outlined,
            label: 'Financeiro',
            onTap: () => onPromptTap('Preciso de ajuda com pagamento.'),
          ),
          _QuickChip(
            icon: Icons.bug_report_outlined,
            label: 'Erro no app',
            onTap: () => onPromptTap('Encontrei um erro no aplicativo.'),
          ),
          _QuickChip(
            icon: Icons.add_circle_outline,
            label: 'Abrir ticket',
            onTap: onOpenTicketTap,
          ),
          _QuickChip(
            icon: Icons.history_rounded,
            label: 'Tickets',
            onTap: onTicketsTap,
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!sending) onSend();
              },
              decoration: InputDecoration(
                hintText: 'Mensagem para o suporte',
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Enviar',
            onPressed: sending ? null : onSend,
            icon:
                sending
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: FxLoading(strokeWidth: 2, color: Colors.white),
                    )
                    : const Icon(Icons.send_rounded),
          ),
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
    final primary = Theme.of(context).colorScheme.primary;
    final bubbleColor =
        msg.isError
            ? EagleTokens.bad.withValues(alpha: 0.10)
            : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.support_agent_rounded,
                size: 15,
                color: primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? primary : bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 18),
                ),
              ),
              child: Text(
                msg.texto,
                style: TextStyle(
                  color:
                      isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(
            Icons.support_agent_rounded,
            size: 15,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: FxLoading(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('digitando...', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NovoTicketSheet extends ConsumerStatefulWidget {
  const _NovoTicketSheet();

  @override
  ConsumerState<_NovoTicketSheet> createState() => _NovoTicketSheetState();
}

class _NovoTicketSheetState extends ConsumerState<_NovoTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _classeCtrl = TextEditingController();

  String _severidade = 'MEDIA';
  bool _enviando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _classeCtrl.dispose();
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
        classeAfetada:
            _classeCtrl.text.trim().isEmpty ? null : _classeCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(ticket);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Abrir ticket',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tituloCtrl,
              decoration: InputDecoration(
                labelText: 'Titulo *',
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator:
                  (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Informe um titulo'
                          : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoCtrl,
              decoration: InputDecoration(
                labelText: 'Descricao *',
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator:
                  (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Descreva o problema'
                          : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _severidade,
              decoration: InputDecoration(
                labelText: 'Severidade *',
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: Icon(Icons.warning_amber_rounded),
              ),
              items:
                  _severidades
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color:
                                    _severidadeColors[s] ?? EagleTokens.inkMute,
                              ),
                              const SizedBox(width: 8),
                              Text(s),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _severidade = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _classeCtrl,
              decoration: InputDecoration(
                labelText: 'Classe afetada',
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: Icon(Icons.code_rounded),
                hintText: 'Ex: TreinoService',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviarTicket,
              icon:
                  _enviando
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: FxLoading(strokeWidth: 2, color: Colors.white),
                      )
                      : const Icon(Icons.send_rounded),
              label: const Text('Enviar ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = SuporteRepository(ref.read(apiClientProvider));
      final tickets = await repo.meusTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Meus tickets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) return const FxLoading();
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Erro ao carregar tickets',
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
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
    final statusColor = _statusColor(context, ticket.status);
    final sevColor =
        _severidadeColors[ticket.severidade] ?? EagleTokens.inkMute;
    final resolvido = ticket.status == 'RESOLVIDO';
    final temResposta = resolvido && ticket.respostaAdmin != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: fxListCardDecoration(context, accent: statusColor),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child:
                temResposta
                    ? ExpansionTile(
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                title: _TicketTileContent(
                  ticket: ticket,
                  statusColor: statusColor,
                  sevColor: sevColor,
                ),
                children: [
                  const Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.support_agent,
                        size: 18,
                        color: EagleTokens.good,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resposta do suporte',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ticket.respostaAdmin!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
                    : ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: _TicketTileContent(
                  ticket: ticket,
                  statusColor: statusColor,
                  sevColor: sevColor,
                ),
              ),
          ),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                ticket.severidade,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: sevColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: sevColor),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Chip(
              label: Text(
                ticket.status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: statusColor),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (ticket.criadoEm != null) ...[
          const SizedBox(height: 4),
          Text(
            'Aberto em ${fxTimeAgo(DateTime.parse(ticket.criadoEm!))}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: EagleTokens.inkMute),
          ),
        ],
      ],
    );
  }
}
