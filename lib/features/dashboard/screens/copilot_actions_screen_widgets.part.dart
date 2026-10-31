part of 'copilot_actions_screen.dart';

/// Tarefa em uma linha: aluno, motivo e prazo. O resto fica no "⋯".
class _TarefaRow extends StatelessWidget {
  const _TarefaRow({
    required this.action,
    required this.concluida,
    required this.ink,
    required this.mute,
    required this.onOpen,
    required this.onConcluir,
    required this.onMais,
  });

  final FilaAcaoResumo action;
  final bool concluida;
  final Color ink;
  final Color mute;
  final VoidCallback onOpen;
  final VoidCallback onConcluir;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    final nome = copilotActionsNome(action);
    final motivo = copilotActionsMotivo(action);
    final selo = copilotActionsSelo(action);
    final primary = Theme.of(context).colorScheme.primary;
    final icone = copilotActionsIcone(action);
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
                  child: Row(
                    children: [
                      if (action.alunoId != null)
                        AlunoAvatar(
                          name: nome,
                          variant: AlunoAvatarVariant.strip,
                        )
                      else
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primary.withValues(alpha: 0.12),
                          child: Icon(icone, size: 18, color: primary),
                        ),
                      const SizedBox(width: TokensStrip.s2),
                      Expanded(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!concluida)
          IconButton(
            tooltip: copilotActionsConcluirLabel(),
            icon: Icon(Icons.check_circle_outline_rounded, color: primary),
            onPressed: onConcluir,
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

/// Vazio de Abertas: tranquilo, com o que foi feito por último.
class _NadaPendente extends StatelessWidget {
  const _NadaPendente({
    required this.titulo,
    required this.ultima,
    required this.ink,
    required this.mute,
  });

  final String titulo;
  final String? ultima;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s5),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: primary.withValues(alpha: 0.12),
            child: Icon(Icons.check_rounded, color: primary, size: 28),
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(titulo, style: FocuxHubTypography.cardTitle(color: ink)),
          if (ultima != null) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              'Última concluída: $ultima',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
          ],
        ],
      ),
    );
  }
}

/// Concluídas de hoje, recolhidas para não competir com o que falta.
class _FeitasHoje extends StatelessWidget {
  const _FeitasHoje({
    required this.acoes,
    required this.ink,
    required this.mute,
  });

  final List<FilaAcaoResumo> acoes;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: fxListCardDecoration(context),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          'Feitas hoje · ${acoes.length}',
          style: FocuxHubTypography.cardTitle(color: ink),
        ),
        children: [
          for (final a in acoes)
            ListTile(
              dense: true,
              leading: Icon(Icons.check_rounded, color: mute, size: 18),
              title: Text(
                copilotActionsNome(a),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.body(color: mute),
              ),
            ),
        ],
      ),
    );
  }
}
