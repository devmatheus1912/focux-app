import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../l10n/pt.dart';
import '../models/progressao_sugestao.dart';
import '../utils/progressao_copy.dart';

enum _Acao { editar, descartar }

/// Uma sugestão na revisão: marca, exercício, de → para, quanto muda e por quê.
/// A diferença não leva cor: em barra assistida, menos carga é mais difícil.
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

  Future<void> _acoes(BuildContext context) async {
    final escolha = await showFxGroupedActionSheet<_Acao>(
      context,
      titulo: sugestao.exercicio,
      grupos: [
        FxActionGroup<_Acao>(null, [
          if (onEditarCarga != null)
            FxActionItem(
              valor: _Acao.editar,
              rotulo: ptS.cargasEditar,
              icone: Icons.edit_outlined,
            ),
          FxActionItem(
            valor: _Acao.descartar,
            rotulo: ptS.cargasDescartar,
            icone: Icons.delete_outline_rounded,
            perigo: true,
          ),
        ]),
      ],
    );
    switch (escolha) {
      case _Acao.editar:
        onEditarCarga?.call();
      case _Acao.descartar:
        onDescartar();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final atual = progressaoPartes(sugestao.cargaAtual);
    final nova = progressaoPartes(sugestao.cargaSugerida);
    final sugerida =
        cargaEditada != null
            ? progressaoKg(cargaEditada!)
            : nova.carga;
    final diferenca = progressaoDiferenca(sugestao, cargaEditada);
    final mudouPrescricao =
        nova.prescricao.isNotEmpty && nova.prescricao != atual.prescricao;
    final motivo = sugestao.justificativa?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s1,
        TokensStrip.s1,
        TokensStrip.s1,
        TokensStrip.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: sugestao.exercicio,
            child: Checkbox(
              value: selecionada,
              activeColor: primary,
              onChanged: (v) => onSelecionar(v ?? false),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (alunoNome != null)
                    Text(alunoNome!, style: FocuxHubTypography.chip(chrome.mute)),
                  Text(
                    sugestao.exercicio,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: TokensStrip.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: FocuxHubTypography.body(color: chrome.mute),
                          children: [
                            TextSpan(text: '${atual.carga}  →  '),
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
                      if (diferenca != null) FxStatusPill(label: diferenca),
                      if (cargaEditada != null)
                        FxStatusPill(label: ptS.cargasEditada),
                    ],
                  ),
                  if (mudouPrescricao)
                    Text(
                      '${atual.prescricao}  →  ${nova.prescricao}',
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  if (motivo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      motivo,
                      maxLines: aberta ? null : 3,
                      overflow: aberta ? null : TextOverflow.ellipsis,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                    if (motivo.length > 110)
                      FxActionLink(
                        label: aberta ? ptS.cargasVerMenos : ptS.cargasVerMais,
                        onTap: onAbrir,
                      ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: ptS.cargasMais,
            icon: Icon(Icons.more_horiz_rounded, color: chrome.mute),
            onPressed: () => _acoes(context),
          ),
        ],
      ),
    );
  }
}
