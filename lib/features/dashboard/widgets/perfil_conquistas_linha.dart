import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/pt.dart';
import '../../evolucao/data/meta_corporal.dart';
import '../../evolucao/widgets/conquista_selo.dart';

/// Quantos selos o topo do perfil mostra; o resto fica no Meu progresso.
const perfilConquistasMax = 3;

/// Largura de cada selo com a legenda (o item: "Cintura", "Supino").
const perfilSeloLegendaLargura = 64.0;

/// "Abdominal / bicicleta": duas linhas antes das reticências.
const perfilSeloLegendaLinhas = 2;

/// Conquistas no topo do perfil do aluno: até [perfilConquistasMax] selos, as
/// mais recentes primeiro, cada um com o item embaixo, e o link para o Meu
/// progresso. Sem conquista, nada.
class PerfilConquistasLinha extends StatelessWidget {
  const PerfilConquistasLinha({
    super.key,
    required this.conquistas,
    required this.onAbrir,
    required this.onVerTodas,
    this.marca,
  });

  /// Já na ordem de [conquistasDe] (mais recente primeiro).
  final List<Conquista> conquistas;
  final ValueChanged<Conquista> onAbrir;
  final VoidCallback onVerTodas;
  final Color? marca;

  @override
  Widget build(BuildContext context) {
    if (conquistas.isEmpty) return const SizedBox.shrink();
    final sobre = fxPaletaSobreMarca(context, accent: marca);
    // O selo mede o contraste contra o fundo de verdade: o cartão escurece a
    // marca (marca clara vira fundo escuro), então o metal sai do fundo, não
    // da marca crua.
    final fundo =
        BrandPalette.cardDeMarca(
          marca ?? Theme.of(context).colorScheme.primary,
          dark: Theme.of(context).brightness == Brightness.dark,
        ).fundo;
    final recente = conquistas.first;
    final link =
        conquistas.length > perfilConquistasMax
            ? ptS.perfilConquistasVerTodas(conquistas.length)
            : ptS.meuProgressoTitulo;
    // Os selos têm a largura deles; quem encolhe (com reticências) é o link,
    // senão texto grande empurrava os selos para fora.
    return Row(
      children: [
        Semantics(
          label: ptS.perfilConquistasResumo(
            conquistas.length,
            recente.tipoRotulo,
            recente.item,
          ),
          // Selos alinhados pelo topo: legenda de uma ou duas linhas não
          // desloca o selo.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in conquistas.take(perfilConquistasMax))
                Padding(
                  padding: const EdgeInsets.only(right: TokensStrip.s2),
                  child: ExcludeSemantics(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TokensStrip.rSm),
                      onTap: () => onAbrir(c),
                      child: SizedBox(
                        width: perfilSeloLegendaLargura,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConquistaSelo(
                              tipo: c.tipo,
                              glifo: conquistaGlifo(c),
                              tamanho: 48,
                              marca: fundo,
                              sobreMarca: true,
                            ),
                            const SizedBox(height: TokensStrip.s1),
                            Text(
                              c.item,
                              maxLines: perfilSeloLegendaLinhas,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.minimo(
                                color: sobre.mute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: link,
              child: InkWell(
                borderRadius: BorderRadius.circular(TokensStrip.rSm),
                onTap: onVerTodas,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          link,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.rotulo(color: sobre.ink),
                        ),
                      ),
                      const SizedBox(width: TokensStrip.s1),
                      Icon(FxIcons.chevronDireitaPequeno, size: 14, color: sobre.ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
