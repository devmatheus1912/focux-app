import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_aneis_concentricos.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_aneis.dart';

List<AnelConcentrico> _aneisDe(
  List<LeituraDoAnel> leituras,
  List<Color> cores,
) => [
  for (final (i, l) in leituras.indexed)
    AnelConcentrico(fracao: l.fracao, cor: cores[i]),
];

String _resumo(List<LeituraDoAnel> l) =>
    ptS.evolucaoAneisAcessivel(l[0].valor, l[1].valor, l[2].valor);

/// Topo da Evolução, igual nas duas visões: anéis e legenda. O aluno ganha uma
/// frase abaixo. [recolhido] vira uma faixa com os 3 valores, ao rolar.
class EvolucaoHero extends StatelessWidget {
  const EvolucaoHero({
    super.key,
    required this.aneis,
    this.doPersonal = true,
    this.frase,
    this.onDefinirMeta,
    this.onMedidas,
    this.recolhido = false,
    this.metaNome,
  });

  /// Faixa recolhida do personal: a coluna Medidas abre o ciclo.
  final VoidCallback? onMedidas;

  final EvolucaoAneis aneis;

  /// Medida da meta do anel ([nomeDaMetaPrincipal]).
  final String? metaNome;
  final bool doPersonal;
  final String? frase;

  /// Só com o anel de meta vazio.
  final VoidCallback? onDefinirMeta;
  final bool recolhido;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final fundo = Theme.of(context).colorScheme.primary;
    final cores = fxCoresDeAnel(fundo);
    final leituras = leiturasDosAneis(
      aneis,
      doPersonal: doPersonal,
      metaNome: metaNome,
    );
    return FxStripCard(
      marca: true,
      padding: const EdgeInsets.all(TokensStrip.s3),
      child: SizedBox(
        width: double.infinity,
        child: AnimatedSize(
          duration: fxMotionDuration(
            context,
            normal: const Duration(milliseconds: 200),
          ),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              recolhido
                  ? Row(
                    children: [
                      for (final (i, l) in leituras.indexed)
                        Expanded(
                          child: _Valor(
                            leitura: l,
                            cor: cores[i],
                            onTap: switch (i) {
                              1 when l.vazio => onDefinirMeta,
                              2 => onMedidas,
                              _ => null,
                            },
                          ),
                        ),
                    ],
                  )
                  : Column(
                    children: [
                      Row(
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
                                    onTap:
                                        i == 1 && l.vazio
                                            ? onDefinirMeta
                                            : null,
                                  ),
                              ],
                            ),
                          ),
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
      ),
    );
  }
}

/// Conteúdo some em degradê sob as abas, sem corte seco.
class EvolucaoFadeTopo extends StatelessWidget {
  const EvolucaoFadeTopo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback:
        (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.03],
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    child: child,
  );
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.leitura, required this.cor, this.onTap});

  final LeituraDoAnel leitura;
  final Color cor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    // Rótulo e valor juntos, um embaixo do outro: antes o valor ficava na
    // outra ponta do cartão e o olho precisava atravessar para ligar os dois.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leitura.rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.chip(sobre.mute),
                ),
                if (onTap == null)
                  Text(
                    leitura.valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(color: sobre.ink),
                  )
                else
                  // Link no mesmo texto das outras linhas: o botão tonal saía
                  // quase preto sobre a marca e parecia desativado.
                  Semantics(
                    button: true,
                    label: leitura.valor,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(TokensStrip.s2),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: Text(
                            '${leitura.valor} ›',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.cardTitle(
                              color: sobre.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Item da faixa recolhida: ponto da cor do anel e valor.
class _Valor extends StatelessWidget {
  const _Valor({required this.leitura, required this.cor, this.onTap});

  final LeituraDoAnel leitura;
  final Color cor;

  /// Coluna que abre uma ação (definir meta, ciclo de medidas).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final conteudo = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: TokensStrip.s1),
            Text(leitura.rotulo, style: FocuxHubTypography.chip(sobre.mute)),
          ],
        ),
        Text(
          leitura.valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: FocuxHubTypography.bodyMuted(
            color: sobre.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    if (onTap == null) return conteudo;
    return Semantics(
      button: true,
      label: '${leitura.rotulo}: ${leitura.valor}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.s2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(child: conteudo),
        ),
      ),
    );
  }
}
