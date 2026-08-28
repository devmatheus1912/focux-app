import 'package:flutter/material.dart';

import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import 'aluno360_copilot_ia_refresh_button.dart';
import 'aluno360_help_sheets.dart';

/// Prioridade do dia — plano com IA, aguardando geração.
class Aluno360CopilotIaPromptSection extends StatelessWidget {
  const Aluno360CopilotIaPromptSection({
    super.key,
    required this.alunoId,
    required this.primary,
    required this.contactPriority,
  });

  final int alunoId;
  final Color primary;
  final bool contactPriority;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);

    return Semantics(
      container: true,
      label: 'Prioridade do dia, gere com IA',
      child: FxSettingsGroup(
        header: contactPriority ? 'Prioridade do dia' : 'Próxima melhor ação',
        caption: 'Sugestão gerada com IA Copiloto',
        helpTooltip: 'Ajuda sobre prioridade do dia',
        onHelpTap: () => showAluno360CopilotHelpSheet(context),
        accent: primary,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_outlined, size: 22, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gere a prioridade com IA',
                            style: Aluno360Layout.panelTitleStyle(context, ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toque em Gerar para montar a sugestão do dia '
                            'com base no perfil atual deste aluno.',
                            style: Aluno360Layout.captionStyle(
                              context,
                            ).copyWith(color: mute, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Aluno360CopilotIaRefreshButton(
                  alunoId: alunoId,
                  primary: primary,
                  prominent: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
