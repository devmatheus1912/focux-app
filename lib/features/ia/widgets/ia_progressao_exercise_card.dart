import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'ia_carga_chip.dart';
import 'ia_expandable_copy.dart';

/// Shared exercise row card for progressão IA result and revisão screens.
class IaProgressaoExerciseCard extends StatelessWidget {
  const IaProgressaoExerciseCard({
    super.key,
    required this.exercicio,
    required this.cargaAtual,
    required this.cargaSugerida,
    this.justificativa,
    this.deltaLabel,
    this.header,
    this.footerActions,
    this.padding = const EdgeInsets.all(14),
  });

  final String exercicio;
  final String cargaAtual;
  final String cargaSugerida;
  final String? justificativa;
  final String? deltaLabel;
  final Widget? header;
  final Widget? footerActions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final atual = cargaAtual.isEmpty ? '—' : cargaAtual;
    final sugerida = cargaSugerida.isEmpty ? '—' : cargaSugerida;

    return Semantics(
      label:
          '$exercicio. Carga atual $atual. Carga sugerida $sugerida.'
          '${deltaLabel != null ? ' Variação $deltaLabel.' : ''}'
          '${justificativa != null && justificativa!.isNotEmpty ? ' $justificativa' : ''}',
      child: DecoratedBox(
        decoration: fxListCardDecoration(context, accent: primary),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],
              Text(
                exercicio,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: IaCargaChip(
                      label: 'Atual',
                      valor: atual,
                      color: TokensStrip.textSecondary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: IaCargaChip(
                      label: 'Sugerido',
                      valor: sugerida,
                      color: primary,
                      deltaLabel: deltaLabel,
                    ),
                  ),
                ],
              ),
              if (justificativa != null && justificativa!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TokensStrip.textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: TokensStrip.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: IaExpandableCopy(
                          text: justificativa!,
                          expandLabel: 'Ler justificativa completa',
                          collapseLabel: 'Ver menos',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: TokensStrip.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (footerActions != null) ...[
                const SizedBox(height: 14),
                footerActions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
