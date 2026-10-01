import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../models/progressao_sugestao.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/progressao_copy.dart';

/// Pedido: o que a IA vai ler, objetivo e observações opcionais.
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
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final titleStyle = FocuxHubTypography.cardTitle(color: ink);
    final mutedStyle = FocuxHubTypography.bodyMuted(
      color: TokensStrip.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: fxListCardDecoration(context, accent: primary),
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fact_check_outlined, size: 18, color: primary),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(progressaoContextoTitulo, style: titleStyle),
                      const SizedBox(height: 2),
                      Text(
                        contexto.when(
                          data: progressaoContextoLine,
                          loading: () => 'Lendo treino ativo…',
                          error:
                              (e, _) =>
                                  isSemTreinoAtivo(e)
                                      ? progressaoSemTreinoAtivo
                                      : 'Treino ativo e execuções das últimas 4 semanas',
                        ),
                        style: mutedStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        Text('Objetivo', style: titleStyle),
        const SizedBox(height: TokensStrip.s2),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            for (final o in ProgressaoObjetivo.values)
              ChoiceChip(
                label: Text(o.label),
                selected: o == objetivo,
                onSelected: enabled ? (_) => onObjetivo(o) : null,
              ),
          ],
        ),
        const SizedBox(height: TokensStrip.s4),
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
          style: FocuxHubTypography.body(color: ink),
          decoration: FxInputDeco.build(
            context,
            progressaoObservacoesLabel,
            hint: progressaoObservacoesHint,
          ).copyWith(alignLabelWithHint: true),
        ),
      ],
    );
  }
}
