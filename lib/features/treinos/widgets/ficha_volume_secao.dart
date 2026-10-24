import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_volume.dart';
import '../utils/ficha_volume_grupos.dart';
import 'ficha_acoes.dart';

String rotuloDoGrupo(S s, GrupoDeLeitura grupo) => switch (grupo) {
  GrupoDeLeitura.peito => s.volumeGrupoPeito,
  GrupoDeLeitura.costas => s.volumeGrupoCostas,
  GrupoDeLeitura.ombros => s.volumeGrupoOmbros,
  GrupoDeLeitura.biceps => s.volumeGrupoBiceps,
  GrupoDeLeitura.triceps => s.volumeGrupoTriceps,
  GrupoDeLeitura.antebraco => s.volumeGrupoAntebraco,
  GrupoDeLeitura.quadriceps => s.volumeGrupoQuadriceps,
  GrupoDeLeitura.posteriorCoxa => s.volumeGrupoPosteriorCoxa,
  GrupoDeLeitura.gluteo => s.volumeGrupoGluteo,
  GrupoDeLeitura.quadril => s.volumeGrupoQuadril,
  GrupoDeLeitura.panturrilha => s.volumeGrupoPanturrilha,
  GrupoDeLeitura.abdomen => s.volumeGrupoAbdomen,
  GrupoDeLeitura.lombar => s.volumeGrupoLombar,
  GrupoDeLeitura.corpoTodo => s.volumeGrupoCorpoTodo,
  GrupoDeLeitura.outros => s.volumeGrupoOutros,
};

/// "Volume da semana": séries de trabalho por grupo muscular. Recolhida por
/// padrão. É só informação: nada alerta, bloqueia nem pinta o volume de bom ou ruim.
/// [origem] (`ficha` ou `modelo`) só serve para a métrica.
class FichaVolumeSecao extends ConsumerStatefulWidget {
  const FichaVolumeSecao({super.key, required this.provider, required this.origem});

  final ProviderListenable<AsyncValue<FichaVolume>> provider;
  final String origem;

  @override
  ConsumerState<FichaVolumeSecao> createState() => _FichaVolumeSecaoState();
}

class _FichaVolumeSecaoState extends ConsumerState<FichaVolumeSecao> {
  var _aberta = false;

  void _alternar() {
    setState(() => _aberta = !_aberta);
    if (_aberta) {
      AnalyticsService.instance.track(
        ProductEvents.fichaVolumeAberto,
        props: {'origem': widget.origem},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(widget.provider).asData?.value;
    if (volume == null) return const SizedBox.shrink();

    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final linhas = linhasDeVolume(volume);

    if (volume.semSeries) {
      return FxTapRow(
        title: s.volumeTitulo,
        subtitle: s.volumeVazio,
        trailing: const SizedBox.shrink(),
        onTap: null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxTapRow(
          title: s.volumeTitulo,
          subtitle: s.volumeSeriesDeTrabalho(volume.totalSeries),
          trailing: Icon(
            _aberta ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: chrome.mute,
          ),
          onTap: _alternar,
        ),
        if (_aberta) ...[
          const SizedBox(height: TokensStrip.s3),
          Text(
            s.volumeReferencia,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          for (final linha in linhas)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s3),
              child: _LinhaDoGrupo(linha: linha, escala: escalaDaBarra(linhas)),
            ),
          if (volume.seriesSemGrupo > 0)
            Text(
              s.volumeSemGrupo(volume.seriesSemGrupo),
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
        ],
      ],
    );
  }
}

class _LinhaDoGrupo extends StatelessWidget {
  const _LinhaDoGrupo({required this.linha, required this.escala});

  final LinhaDeVolume linha;
  final int escala;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final nomes = nomesDosDias(s);
    final dias = linha.dias.map((d) => nomes[d - 1]).join(' · ');
    final rotulo = rotuloDoGrupo(s, linha.grupo);

    return Semantics(
      label: '$rotulo, ${s.volumeSeriesDeTrabalho(linha.series)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rotulo,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
              ),
              Text(
                '${linha.series}',
                style: FocuxHubTypography.metric(color: chrome.ink),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s1),
          _Barra(series: linha.series, escala: escala),
          if (dias.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(dias, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
          ],
        ],
      ),
    );
  }
}

/// Barra neutra: a faixa de referência é só um fundo mais claro, sem cor de alerta.
class _Barra extends StatelessWidget {
  const _Barra({required this.series, required this.escala});

  final int series;
  final int escala;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return LayoutBuilder(
      builder: (context, caixa) {
        final largura = caixa.maxWidth;
        return SizedBox(
          height: 10,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: chrome.line.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(TokensStrip.rPill),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('faixa-referencia'),
                left: largura * proporcaoDaBarra(faixaReferenciaMin, escala),
                width:
                    largura *
                    (proporcaoDaBarra(faixaReferenciaMax, escala) -
                        proporcaoDaBarra(faixaReferenciaMin, escala)),
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: chrome.mute.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(TokensStrip.rPill),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('barra-de-series'),
                left: 0,
                width: largura * proporcaoDaBarra(series, escala),
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: chrome.brand,
                    borderRadius: BorderRadius.circular(TokensStrip.rPill),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
