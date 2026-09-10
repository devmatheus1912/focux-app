part of 'suporte_screen.dart';

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
        10 +
            math.max(
              MediaQuery.viewPaddingOf(context).bottom,
              MediaQuery.viewInsetsOf(context).bottom,
            ),
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
              inputFormatters: [
                LengthLimitingTextInputFormatter(suporteChatMax),
              ],
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

    return Semantics(
      label: isUser ? 'Você: ${msg.texto}' : 'Suporte: ${msg.texto}',
      container: true,
      child: Padding(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: FxLoading(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'digitando...',
                style: FocuxHubTypography.bodyMuted(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
