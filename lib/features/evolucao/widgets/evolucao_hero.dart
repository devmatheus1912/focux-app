import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_aneis_concentricos.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_aneis.dart';

List<AnelConcentrico> _aneisDe(List<LeituraDoAnel> leituras, List<Color> cores) => [
  for (final (i, l) in leituras.indexed)
    AnelConcentrico(fracao: l.fracao, cor: cores[i]),
];

String _resumo(List<LeituraDoAnel> l) =>
    ptS.evolucaoAneisAcessivel(l[0].valor, l[1].valor, l[2].valor);

/// Topo da Evolução. Personal: anéis e legenda, sem rolar. Aluno: anel grande,
/// os três valores e uma frase.
class EvolucaoHero extends StatelessWidget {
  const EvolucaoHero({
    super.key,
    required this.aneis,
    this.doPersonal = true,
    this.frase,
    this.onDefinirMeta,
  });

  final EvolucaoAneis aneis;
  final bool doPersonal;
  final String? frase;

  /// Só com o anel de meta vazio.
  final VoidCallback? onDefinirMeta;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final fundo = Theme.of(context).colorScheme.primary;
    final cores = fxCoresDeAnel(fundo);
    final leituras = leiturasDosAneis(aneis, doPersonal: doPersonal);
    return FxStripCard(
      marca: true,
      padding: const EdgeInsets.all(TokensStrip.s3),
      child: SizedBox(
        width: double.infinity,
        child: doPersonal
            ? Row(
              children: [
                FxAneisConcentricos(
                  aneis: _aneisDe(leituras, cores),
                  resumo: _resumo(leituras),
                ),
                const SizedBox(width: TokensStrip.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, l) in leituras.indexed)
                        _Legenda(
                          leitura: l,
                          cor: cores[i],
                          onTap: i == 1 && l.vazio ? onDefinirMeta : null,
                        ),
                    ],
                  ),
                ),
              ],
            )
            : Column(
              children: [
                FxAneisConcentricos(
                  tamanho: 168,
                  aneis: _aneisDe(leituras, cores),
                  resumo: _resumo(leituras),
                  centro: Text(
                    ptS.evolucaoAnelSemana,
                    style: FocuxHubTypography.chip(sobre.ink),
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
                Row(
                  children: [
                    for (final (i, l) in leituras.indexed)
                      Expanded(child: _Valor(leitura: l, cor: cores[i])),
                  ],
                ),
                if (frase case final frase?) ...[
                  const SizedBox(height: TokensStrip.s3),
                  Text(
                    frase,
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.body(color: sobre.ink),
                  ),
                ],
              ],
            ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.leitura, required this.cor, this.onTap});

  final LeituraDoAnel leitura;
  final Color cor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: TokensStrip.s2),
          Text(leitura.rotulo, style: FocuxHubTypography.chip(sobre.mute)),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: onTap == null
                ? Text(
                  leitura.valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: FocuxHubTypography.cardTitle(color: sobre.ink),
                )
                : Align(
                  alignment: Alignment.centerRight,
                  child: Theme(
                    data: fxTemaSobreMarca(context),
                    child: FxTonalButton(
                      label: leitura.valor,
                      compact: true,
                      onPressed: onTap,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor({required this.leitura, required this.cor});

  final LeituraDoAnel leitura;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    return Column(
      children: [
        Text(
          leitura.rotulo,
          textAlign: TextAlign.center,
          style: FocuxHubTypography.chip(sobre.mute),
        ),
        const SizedBox(height: 2),
        Text(
          leitura.valor,
          textAlign: TextAlign.center,
          style: FocuxHubTypography.bodyMuted(
            color: sobre.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Mini-anel: o mesmo resumo no Hoje do aluno, no 360 e no Relatório.
class EvolucaoMiniAneis extends StatelessWidget {
  const EvolucaoMiniAneis({
    super.key,
    required this.aneis,
    required this.doPersonal,
    this.onTap,
  });

  final EvolucaoAneis aneis;
  final bool doPersonal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = fxListCardDecoration(context);
    final scheme = Theme.of(context).colorScheme;
    final leituras = leiturasDosAneis(aneis, doPersonal: doPersonal);
    final cores = fxCoresDeAnel(scheme.surface);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: chrome,
          child: Row(
            children: [
              FxAneisConcentricos(
                tamanho: 56,
                aneis: _aneisDe(leituras, cores),
                resumo: _resumo(leituras),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final l in leituras)
                        Text(
                          '${l.rotulo}: ${l.valor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: scheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
