import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/branded_app_identity.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/suporte_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../utils/suporte_display.dart';

part 'suporte_screen_widgets.part.dart';
part 'suporte_screen_ticket_sheet.part.dart';
part 'suporte_screen_tickets.part.dart';

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
      FeedbackHelper.showError(context, friendlyError(e));
      _scrollToBottom();
    }
  }

  Future<void> _abrirTicketSheet() async {
    final ticket = await showFxHomeSheet<SuporteTicket>(
      context,
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
    FeedbackHelper.showSuccess(
      context,
      'Ticket #${ticket.id} criado com sucesso.',
    );
    _scrollToBottom();
  }

  void _abrirTicketsSheet() {
    showFxHomeSheet<void>(context, builder: (_) => const _MeusTicketsTab());
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
    return fxScreenA11yScope(
      label: 'Suporte',
      child: FxShellScaffold(
        constrainWidth: false,
        useMesh: true,
        extendBody: true,
        safeArea: false,
        body: FxContentWidthLimiter(
          child: SafeArea(
            child: Column(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      14,
                      16,
                      18,
                    ),
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
        ),
      ),
    );
  }
}
