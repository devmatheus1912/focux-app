import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/ia_copiloto_display.dart';

/// Abertura do Copiloto: quem precisa de atenção, depois qualquer outro aluno.
class CopilotoCardView extends StatelessWidget {
  const CopilotoCardView({
    super.key,
    required this.prioridades,
    required this.tarefasAbertas,
    required this.alunoNome,
    required this.onAnalisar,
    required this.onAnalisarSelecionado,
    required this.onEscolherAluno,
    required this.onVerTarefas,
    this.podeAnalisar = true,
  });

  /// Cota esgotada: sai todo botão de analisar; a lista continua de leitura.
  final bool podeAnalisar;
  final List<CopilotoPrioridade> prioridades;
  final int tarefasAbertas;

  /// Aluno já escolhido nesta tela; nulo antes da primeira escolha.
  final String? alunoNome;
  final void Function(int alunoId, String nome) onAnalisar;
  final VoidCallback onAnalisarSelecionado;
  final VoidCallback onEscolherAluno;
  final VoidCallback onVerTarefas;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final nome = alunoNome?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (nome.isNotEmpty && podeAnalisar) ...[
            FxLiquidPrimaryButton(
              label: s.copilotoAnalisar(nome),
              onPressed: onAnalisarSelecionado,
            ),
            const SizedBox(height: TokensStrip.s4),
          ],
          if (prioridades.isEmpty)
            FxEmptyState(
              icon: 'spark',
              title: s.copilotoSemPrioridadesTitulo,
              subtitle: s.copilotoRevisaoFrase,
              action:
                  podeAnalisar
                      ? FxEmptyAction(
                        label: s.copilotoAnalisarUmAluno,
                        onTap: onEscolherAluno,
                      )
                      : null,
            )
          else ...[
            Text(
              s.copilotoQuemPrecisa,
              style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              s.copilotoRevisaoFrase,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s3),
            Container(
              decoration: fxListCardDecoration(context),
              child: Column(
                children: [
                  for (final (i, p) in prioridades.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _PrioridadeRow(
                      prioridade: p,
                      onAnalisar:
                          podeAnalisar
                              ? () => onAnalisar(p.alunoId, p.nome)
                              : null,
                    ),
                  ],
                ],
              ),
            ),
            if (podeAnalisar) ...[
              const SizedBox(height: TokensStrip.s3),
              FxTonalButton(
                label: s.copilotoAnalisarOutro,
                expanded: true,
                onPressed: onEscolherAluno,
              ),
            ],
          ],
          if (tarefasAbertas > 0) ...[
            const SizedBox(height: TokensStrip.s2),
            FxTonalButton(
              label: s.copilotoVerTarefasN(tarefasAbertas),
              expanded: true,
              onPressed: onVerTarefas,
            ),
          ],
        ],
      ),
    );
  }
}

class _PrioridadeRow extends StatelessWidget {
  const _PrioridadeRow({required this.prioridade, required this.onAnalisar});

  final CopilotoPrioridade prioridade;
  final VoidCallback? onAnalisar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.all(TokensStrip.s3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prioridade.nome,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  prioridade.motivo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
            ),
          ),
          if (onAnalisar case final analisar?) ...[
            const SizedBox(width: TokensStrip.s2),
            FxActionChip(
              label: s.copilotoAnalisarCurto,
              accent: Theme.of(context).colorScheme.primary,
              isDark: chrome.isDark,
              onPressed: analisar,
            ),
          ],
        ],
      ),
    );
  }
}
