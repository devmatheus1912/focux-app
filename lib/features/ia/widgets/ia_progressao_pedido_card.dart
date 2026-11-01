import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/pt.dart';
import '../models/progressao_sugestao.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/progressao_copy.dart';

/// Pedido: base da sugestão, objetivo e o que considerar.
class IaProgressaoPedidoCard extends StatelessWidget {
  const IaProgressaoPedidoCard({
    super.key,
    required this.contexto,
    required this.objetivo,
    required this.onObjetivo,
    required this.observacoes,
    this.enabled = true,
  });

  final AsyncValue<ProgressaoContextoResumo> contexto;
  final ProgressaoObjetivo objetivo;
  final ValueChanged<ProgressaoObjetivo> onObjetivo;
  final TextEditingController observacoes;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final sobre = fxPaletaSobreMarca(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxStripCard(
          marca: true,
          padding: const EdgeInsets.all(TokensStrip.s3),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progressaoContextoTitulo,
                  style: FocuxHubTypography.cardTitle(color: sobre.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  contexto.when(
                    data: progressaoContextoLine,
                    loading: () => ptS.cargasLendoTreino,
                    error:
                        (e, _) =>
                            isSemTreinoAtivo(e)
                                ? progressaoSemTreinoAtivo
                                : ptS.cargasBasePadrao,
                  ),
                  style: FocuxHubTypography.bodyMuted(color: sobre.mute),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        Text(
          ptS.cargasObjetivo,
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s2),
        IgnorePointer(
          ignoring: !enabled,
          child: FxChoiceStrip<ProgressaoObjetivo>(
            itens: [
              for (final o in ProgressaoObjetivo.values)
                FxChoiceItem(value: o, label: o.label),
            ],
            selecionado: objetivo,
            onSelecionar: onObjetivo,
          ),
        ),
        const SizedBox(height: TokensStrip.s1),
        Text(
          objetivo.descricao,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
        const SizedBox(height: TokensStrip.s4),
        Text(
          progressaoAdicionarObservacao,
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s2),
        FxQuickChips<String>(
          itens: progressaoAtalhosObservacao,
          selecionado: null,
          onSelecionar: (atalho) {
            if (!enabled) return;
            final atual = observacoes.text.trim();
            observacoes.text = atual.isEmpty ? atalho : '$atual, $atalho';
          },
        ),
        const SizedBox(height: TokensStrip.s2),
        TextField(
          controller: observacoes,
          enabled: enabled,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
          inputFormatters: [
            LengthLimitingTextInputFormatter(progressaoObservacoesMax),
          ],
          style: FocuxHubTypography.body(color: chrome.ink),
          decoration: FxInputDeco.build(
            context,
            progressaoObservacoesHint,
          ).copyWith(alignLabelWithHint: true),
        ),
      ],
    );
  }
}
