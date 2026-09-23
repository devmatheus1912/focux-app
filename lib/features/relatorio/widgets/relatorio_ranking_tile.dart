import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/relatorio_repository.dart';
import '../utils/relatorio_global_display.dart';

class RelatorioRankingTile extends StatelessWidget {
  const RelatorioRankingTile({
    super.key,
    required this.aluno,
    required this.attention,
    required this.accentFirst,
    required this.onTap,
  });

  final ResumoAluno aluno;
  final bool attention;
  final bool accentFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baixo =
        attention &&
        aluno.totalTreinos > 0 &&
        aluno.treinosConcluidos * 100 < aluno.totalTreinos * 50;
    return Semantics(
      label:
          '${aluno.alunoNome}. '
          '${relatorioAderenciaPercentLabel(aluno.treinosConcluidos, aluno.totalTreinos)}. '
          '${relatorioTreinosSubtitle(aluno.treinosConcluidos, aluno.totalTreinos)}. '
          '${relatorioUltimoTreinoLabel(aluno.ultimoTreino)}',
      button: true,
      child: FxSatelliteListTile(
        title: aluno.alunoNome,
        subtitle: Text(
          relatorioTreinosSubtitle(aluno.treinosConcluidos, aluno.totalTreinos),
        ),
        trailing: Text(
          relatorioAderenciaPercentLabel(
            aluno.treinosConcluidos,
            aluno.totalTreinos,
          ),
          style: FocuxHubTypography.bodyMuted(
            color: baixo ? EagleTokens.bad : fxScreenMute(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        // Atenção = cor no %; sem glow full-bleed (design ref: risco = chip).
        accent: accentFirst && !attention
            ? Theme.of(context).colorScheme.primary
            : null,
        onTap: onTap,
      ),
    );
  }
}
