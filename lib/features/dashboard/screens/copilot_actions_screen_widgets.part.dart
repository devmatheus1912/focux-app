part of 'copilot_actions_screen.dart';

/// Tarefa em uma linha: aluno, motivo e prazo. O resto fica no "⋯".
class _TarefaRow extends StatelessWidget {
  const _TarefaRow({
    required this.action,
    required this.concluida,
    required this.ink,
    required this.mute,
    required this.onOpen,
    required this.onMais,
  });

  final FilaAcaoResumo action;
  final bool concluida;
  final Color ink;
  final Color mute;
  final VoidCallback onOpen;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    final nome = copilotActionsNome(action);
    final motivo = copilotActionsMotivo(action);
    final selo = copilotActionsSelo(action);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '$nome. $motivo${concluida ? '' : '. $selo'}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s3,
                    TokensStrip.s2,
                    TokensStrip.s1,
                    TokensStrip.s2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.cardTitle(color: ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        motivo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.bodyMuted(color: mute),
                      ),
                      if (!concluida) ...[
                        const SizedBox(height: TokensStrip.s1),
                        FxStatusPill(
                          label: selo,
                          tone:
                              selo == 'Hoje'
                                  ? FxPillTone.warning
                                  : FxPillTone.neutral,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Opções da tarefa',
          icon: Icon(Icons.more_horiz_rounded, color: mute),
          onPressed: onMais,
        ),
      ],
    );
  }
}
