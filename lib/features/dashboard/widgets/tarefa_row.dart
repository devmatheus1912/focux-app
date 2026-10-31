import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../data/command_center_data.dart';
import '../utils/copilot_actions_display.dart';

/// Uma tarefa: quem, por quê e um verbo. Concluir é direto; o resto, no "⋯".
class TarefaRow extends StatelessWidget {
  const TarefaRow({
    super.key,
    required this.action,
    required this.concluida,
    required this.ink,
    required this.mute,
    required this.onOpen,
    required this.onConcluir,
    required this.onMais,
    this.fotoUrl,
  });

  final FilaAcaoResumo action;
  final bool concluida;
  final Color ink;
  final Color mute;
  final VoidCallback onOpen;
  final VoidCallback onConcluir;
  final VoidCallback onMais;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    final nome = copilotActionsNome(action);
    final motivo = copilotActionsMotivo(action);
    final selo = copilotActionsSelo(action);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '$nome. $motivo${concluida ? '' : '. $selo'}',
          excludeSemantics: true,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s3,
                TokensStrip.s2,
                TokensStrip.s3,
                TokensStrip.s1,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (action.alunoId != null)
                    AlunoAvatar(
                      name: nome,
                      photoUrl: fotoUrl,
                      variant: AlunoAvatarVariant.strip,
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      child: Icon(
                        copilotActionsIcone(action),
                        size: 18,
                        color: primary,
                      ),
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
                                selo == ptS.tarefasGrupoHoje
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s3,
            0,
            TokensStrip.s1,
            TokensStrip.s1,
          ),
          child: Row(
            children: [
              if (!concluida)
                FxTonalButton(
                  label: copilotActionsVerbo(action),
                  compact: true,
                  onPressed: onOpen,
                ),
              const Spacer(),
              if (!concluida)
                IconButton(
                  tooltip: copilotActionsConcluirLabel(),
                  icon: Icon(
                    Icons.check_circle_outline_rounded,
                    color: primary,
                  ),
                  onPressed: onConcluir,
                ),
              IconButton(
                tooltip: 'Opções da tarefa',
                icon: Icon(Icons.more_horiz_rounded, color: mute),
                onPressed: onMais,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vazio de Abertas: tranquilo, com o que foi feito por último.
class TarefasNadaPendente extends StatelessWidget {
  const TarefasNadaPendente({
    super.key,
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
          if (ultima case final nome?) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              ptS.tarefasUltimaConcluida(nome),
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
          ],
        ],
      ),
    );
  }
}
