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
        10,
      ),
      decoration:
          highlighted
              ? fxListCardDecoration(context, accent: brand, selected: true)
              : fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted) ...[
            Text(
              'Próxima ação',
              style: TextStyle(
                color: brand,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Copiloto · $mode',
                      style: TextStyle(
                        color: brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
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
          const SizedBox(height: 9),
          Text(
            action.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, fontSize: 12, height: 1.32),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              if (canOpen)
                DashboardHomeActionChip(
                  label: copilotActionsOpenAlunoLabel(isDone),
                  accent: brand,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onPressed: onOpen,
                ),
              if (isDone)
                DashboardHomeActionChip(
                  label: copilotActionsReabrirLabel(),
                  accent: brand,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onPressed: onReopen,
                )
              else ...[
                DashboardHomeActionChip(
                  label: copilotActionsAdiarLabel(),
                  accent: brand,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onPressed: onSnooze,
                ),
                DashboardHomeActionChip(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w900,
                        ),
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
                  style: TextStyle(color: mute, fontSize: 11.8, height: 1.3),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    DashboardHomeActionChip(
                      label: action.ctaLabel,
                      accent: brand,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      onPressed: onOpen,
                    ),
                    if (isDone)
                      DashboardHomeActionChip(
                        label: copilotActionsReabrirLabel(),
                        accent: brand,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        onPressed: onReopen,
                      )
                    else ...[
                      DashboardHomeActionChip(
                        label: copilotActionsAdiarLabel(),
                        accent: brand,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        onPressed: onSnooze,
                      ),
                      DashboardHomeActionChip(
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
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
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
        Text(
          title,
          style: TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          detail,
          style: TextStyle(
            color: mute,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
