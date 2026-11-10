import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/ia_copiloto_display.dart';
import '../../../core/theme/fx_icons.dart';

/// Abertura do Copiloto: quem precisa de atenção, depois qualquer outro aluno.
/// Um só botão principal na tela; escolher o aluno já analisa.
class CopilotoCardView extends StatelessWidget {
  const CopilotoCardView({
    super.key,
    required this.prioridades,
    required this.tarefasAbertas,
    required this.onAnalisar,
    required this.onEscolherAluno,
    required this.onVerTarefas,
    this.podeAnalisar = true,
  });

  /// Cota esgotada: sai todo botão de analisar; a lista continua de leitura.
  final bool podeAnalisar;
  final List<CopilotoPrioridade> prioridades;
  final int tarefasAbertas;
  final void Function(int alunoId, String nome) onAnalisar;
  final VoidCallback onEscolherAluno;
  final VoidCallback onVerTarefas;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prioridades.isEmpty)
            FxEmptyState(
              icon: FxIcons.ia,
              title: s.copilotoSemPrioridadesTitulo,
              subtitle:
                  podeAnalisar
                      ? '${s.copilotoRevisaoFrase} ${iaCopilotoCustoAnalise()}'
                      : s.copilotoRevisaoFrase,
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
              style: FocuxHubTypography.sectionTitle(
                context,
                color: chrome.ink,
              ),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              podeAnalisar
                  ? '${s.copilotoRevisaoFrase} ${iaCopilotoCustoAnalise()}'
                  : s.copilotoRevisaoFrase,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s3),
            // O primeiro é quem mais precisa: bloco da marca, fora da lista.
            FxStripCard(
              marca: true,
              padding: EdgeInsets.zero,
              child: _PrioridadeRow(
                prioridade: prioridades.first,
                sobreMarca: true,
                onAnalisar:
                    podeAnalisar
                        ? () => onAnalisar(
                          prioridades.first.alunoId,
                          prioridades.first.nome,
                        )
                        : null,
              ),
            ),
            if (prioridades.length > 1) ...[
              const SizedBox(height: TokensStrip.s2),
              Container(
                decoration: fxListCardDecoration(context),
                child: Column(
                  children: [
                    for (final (i, p) in prioridades.skip(1).indexed) ...[
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
            ],
            if (podeAnalisar) ...[
              const SizedBox(height: TokensStrip.s3),
              FxTonalButton(
                label: s.copilotoAnalisarOutro,
                expanded: true,
                onPressed: onEscolherAluno,
              ),
            ],
          ],
          // Só quando há tarefas além das que a abertura já mostra.
          if (tarefasAbertas > prioridades.length) ...[
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
  const _PrioridadeRow({
    required this.prioridade,
    required this.onAnalisar,
    this.sobreMarca = false,
  });

  final CopilotoPrioridade prioridade;
  final VoidCallback? onAnalisar;
  final bool sobreMarca;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome =
        sobreMarca ? fxPaletaSobreMarca(context) : ShellChrome.of(context);
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
            // Sobre o bloco da marca: cor da paleta da marca (o chip do tema
            // sai quase preto sobre o teal).
            if (sobreMarca)
              FxTonalButton(
                label: s.copilotoAnalisarCurto,
                compact: true,
                fundo: chrome.ink.withValues(alpha: 0.16),
                texto: chrome.ink,
                onPressed: analisar,
              )
            else
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
