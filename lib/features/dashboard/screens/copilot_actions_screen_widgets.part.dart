part of 'copilot_actions_screen.dart';

class _CopilotTaskCard extends StatelessWidget {
  const _CopilotTaskCard({
    required this.action,
    required this.status,
    required this.highlighted,
    required this.ink,
    required this.mute,
    required this.brand,
    required this.onOpen,
    required this.onComplete,
    required this.onSnooze,
    required this.onReopen,
  });

  final FilaAcaoResumo action;
  final String status;
  final bool highlighted;
  final Color ink;
  final Color mute;
  final Color brand;
  final VoidCallback onOpen;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final mode = copilotActionsModeLabel(action);
    final isDone = status == copilotActionsStatusConcluido;
    final canOpen = action.acaoUrl.startsWith('/');
    return Container(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s3,
        TokensStrip.s3,
        TokensStrip.s3,
        TokensStrip.s3,
      ),
      decoration:
          highlighted
              ? fxListCardDecoration(context, accent: brand, selected: true)
              : fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted) ...[
            Text('Próxima ação', style: FocuxHubTypography.chip(brand)),
            const SizedBox(height: TokensStrip.s2),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaskIcon(icon: Icons.auto_awesome, brand: brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.cardTitle(color: ink),
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      'Copiloto · $mode',
                      style: FocuxHubTypography.chip(brand),
                    ),
                  ],
                ),
              ),
              _CompactPill(
                label: copilotActionsDeadlineLabel(action, status),
                color: isDone ? mute : brand,
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            action.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              if (canOpen)
                FxActionChip(
                  label: copilotActionsOpenAlunoLabel(isDone),
                  accent: brand,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onPressed: onOpen,
                  solid: highlighted,
                ),
              if (isDone)
                FxActionChip(
                  label: copilotActionsReabrirLabel(),
                  accent: brand,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onPressed: onReopen,
                )
              else ...[
                FxActionChip(
                  label: copilotActionsAdiarLabel(),
                  accent: brand,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onPressed: onSnooze,
                ),
                FxActionChip(
                  label: copilotActionsConcluirLabel(),
                  accent: brand,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onPressed: onComplete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarSignalCard extends StatelessWidget {
  const _RadarSignalCard({
    required this.action,
    required this.status,
    required this.ink,
    required this.mute,
    required this.brand,
    required this.onOpen,
    required this.onComplete,
    required this.onSnooze,
    required this.onReopen,
  });

  final FilaAcaoResumo action;
  final String status;
  final Color ink;
  final Color mute;
  final Color brand;
  final VoidCallback onOpen;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final isDone = status == copilotActionsStatusConcluido;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskIcon(icon: Icons.sensors, brand: brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.cardTitle(color: ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CompactPill(label: action.prioridade, color: brand),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  action.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    FxActionChip(
                      label: action.ctaLabel,
                      accent: brand,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      onPressed: onOpen,
                    ),
                    if (isDone)
                      FxActionChip(
                        label: copilotActionsReabrirLabel(),
                        accent: brand,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        onPressed: onReopen,
                      )
                    else ...[
                      FxActionChip(
                        label: copilotActionsAdiarLabel(),
                        accent: brand,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        onPressed: onSnooze,
                      ),
                      FxActionChip(
                        label: copilotActionsConcluirLabel(),
                        accent: brand,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        onPressed: onComplete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  const _TaskIcon({required this.icon, required this.brand});

  final IconData icon;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: brand, size: 17),
    );
  }
}

class _CompactPill extends StatelessWidget {
  const _CompactPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: FocuxHubTypography.chip(color),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.detail,
    required this.ink,
    required this.mute,
  });

  final String title;
  final String detail;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: FocuxHubTypography.cardTitle(color: ink)),
        const SizedBox(width: TokensStrip.s2),
        Text(detail, style: FocuxHubTypography.bodyMuted(color: mute)),
      ],
    );
  }
}
