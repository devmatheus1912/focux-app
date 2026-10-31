import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../models/progressao_sugestao.dart';

/// Uma sugestão na revisão: marca, exercício, de → para e o motivo. O toque
/// abre o motivo inteiro e as ações que não cabem em toda linha.
class ProgressaoRevisaoLinha extends StatelessWidget {
  const ProgressaoRevisaoLinha({
    super.key,
    required this.sugestao,
    required this.selecionada,
    required this.aberta,
    required this.onSelecionar,
    required this.onAbrir,
    required this.onDescartar,
    this.cargaEditada,
    this.onEditarCarga,
    this.alunoNome,
  });

  final ProgressaoSugestao sugestao;
  final bool selecionada;
  final bool aberta;
  final ValueChanged<bool> onSelecionar;
  final VoidCallback onAbrir;
  final VoidCallback onDescartar;
  final double? cargaEditada;
  final VoidCallback? onEditarCarga;

  /// Na fila geral, de vários alunos.
  final String? alunoNome;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final sugerida =
        cargaEditada != null
            ? '${cargaEditada!.toStringAsFixed(cargaEditada! % 1 == 0 ? 0 : 1).replaceAll('.', ',')} kg'
            : sugestao.cargaSugerida;
    final motivo = sugestao.justificativa?.trim() ?? '';
    return InkWell(
      onTap: onAbrir,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s1,
          TokensStrip.s1,
          TokensStrip.s3,
          TokensStrip.s2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selecionada,
              activeColor: primary,
              onChanged: (v) => onSelecionar(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: TokensStrip.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alunoNome != null)
                      Text(
                        alunoNome!,
                        style: FocuxHubTypography.chip(chrome.mute),
                      ),
                    Text(
                      sugestao.exercicio,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: FocuxHubTypography.body(color: chrome.mute),
                        children: [
                          TextSpan(text: '${sugestao.cargaAtual}  →  '),
                          TextSpan(
                            text: sugerida,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (motivo.isNotEmpty)
                      Text(
                        motivo,
                        maxLines: aberta ? null : 1,
                        overflow: aberta ? null : TextOverflow.ellipsis,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    if (aberta) ...[
                      const SizedBox(height: TokensStrip.s2),
                      Wrap(
                        spacing: TokensStrip.s2,
                        runSpacing: TokensStrip.s1,
                        children: [
                          if (onEditarCarga != null)
                            FxTonalButton(
                              label: ptS.cargasEditar,
                              compact: true,
                              onPressed: onEditarCarga,
                            ),
                          FxTonalButton(
                            label: ptS.cargasDescartar,
                            compact: true,
                            onPressed: onDescartar,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
