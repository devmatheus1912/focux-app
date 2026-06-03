part of 'aluno_detail_screen.dart';

class _Aluno360Signal {
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _Aluno360Signal({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });
}

class _ProfileGap {
  final IconData icon;
  final String title;
  final String detail;
  final String route;

  const _ProfileGap({
    required this.icon,
    required this.title,
    required this.detail,
    required this.route,
  });
}

class _Aluno360SignalTile extends StatelessWidget {
  final _Aluno360Signal signal;

  const _Aluno360SignalTile({required this.signal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: signal.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  signal.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopilotPrescription extends StatelessWidget {
  final String title;
  final String action;
  final String reason;
  final Color color;

  const _CopilotPrescription({
    required this.title,
    required this.action,
    required this.reason,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: color, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          action,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.28,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          reason,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: mute, fontSize: 12, height: 1.25),
        ),
      ],
    );
  }
}

class _CopilotTaskStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CopilotTaskStatus({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Aluno360ActionRow extends StatefulWidget {
  final Aluno aluno;
  final Color primary;
  final FilaAcaoResumo? existingTask;
  final String acao;
  final Future<bool> Function(String acao) onAssign;
  final void Function(String acao) onPrepareMessage;

  const _Aluno360ActionRow({
    required this.aluno,
    required this.primary,
    required this.existingTask,
    required this.acao,
    required this.onAssign,
    required this.onPrepareMessage,
  });

  @override
  State<_Aluno360ActionRow> createState() => _Aluno360ActionRowState();
}

class _Aluno360ActionRowState extends State<_Aluno360ActionRow> {
  bool _creating = false;
  bool _created = false;

  Future<void> _handlePrimary() async {
    if (widget.existingTask != null || _created) {
      context.push('/dashboard/command-center/copiloto');
      return;
    }
    setState(() => _creating = true);
    final created = await widget.onAssign(widget.acao);
    if (!mounted) return;
    setState(() {
      _creating = false;
      _created = created;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTask = widget.existingTask != null || _created;
    final primaryLabel =
        hasTask ? 'Ver tarefa' : (_creating ? 'Criando...' : 'Criar tarefa');
    return Row(
      children: [
        Expanded(
          child: FxLiquidPrimaryButton(
            loading: _creating,
            icon:
                hasTask
                    ? Icons.open_in_new_rounded
                    : Icons.task_alt_rounded,
            label: primaryLabel,
            onPressed: _creating ? null : _handlePrimary,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 112,
          height: 44,
          child: InkWell(
            onTap: () {
              widget.onPrepareMessage(widget.acao);
            },
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: widget.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Abrir chat',
                    style: TextStyle(
                      color: widget.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniAutonomyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniAutonomyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyMiniState extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _EmptyMiniState({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mute,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

