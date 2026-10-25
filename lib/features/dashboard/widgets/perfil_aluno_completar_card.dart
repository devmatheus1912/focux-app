import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_row.dart';
import '../../../l10n/app_localizations.dart';

/// O único lugar do Perfil que fala do cadastro incompleto: progresso, o que
/// falta e um verbo. Em 100% não existe.
class PerfilAlunoCompletarCard extends StatelessWidget {
  const PerfilAlunoCompletarCard({
    super.key,
    required this.score,
    required this.queFalta,
    required this.onTap,
  });

  final int score;
  final String queFalta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (score >= 100) return const SizedBox.shrink();
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final progresso = (score.clamp(0, 100)) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxActionRow(
          leading: Icons.person_outline,
          titulo: s.alunoPerfilCompletarTitulo,
          motivo: queFalta.isEmpty
              ? s.alunoPerfilCompletarPct(score)
              : '${s.alunoPerfilCompletarPct(score)} · ${s.alunoPerfilCompletarFalta(queFalta)}',
          verbo: s.alunoPerfilCompletarVerbo,
          onTap: onTap,
        ),
        const SizedBox(height: TokensStrip.s2),
        Semantics(
          label: s.alunoPerfilCompletarPct(score),
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 4,
              backgroundColor: chrome.line,
              valueColor: AlwaysStoppedAnimation(chrome.brand),
            ),
          ),
        ),
      ],
    );
  }
}

/// Estilo do e-mail sob o nome.
TextStyle perfilAlunoEmailStyle(ShellPalette chrome) =>
    FocuxHubTypography.bodyMuted(color: chrome.mute);
