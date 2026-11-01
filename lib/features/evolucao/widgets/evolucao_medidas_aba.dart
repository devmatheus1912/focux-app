import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_grafico_linha.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_display.dart';
import '../utils/evolucao_series.dart';

/// Aba Medidas, igual para personal e aluno. A linha abre [onAbrirMedida].
class EvolucaoMedidasAba extends StatefulWidget {
  const EvolucaoMedidasAba({
    super.key,
    required this.medidas,
    required this.vazioSubtitulo,
    required this.onAtualizar,
    this.onAbrirMedida,
  });

  final List<MedidaCorporal> medidas;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;
  final ValueChanged<MedidaCorporal>? onAbrirMedida;

  @override
  State<EvolucaoMedidasAba> createState() => _EvolucaoMedidasAbaState();
}

class _EvolucaoMedidasAbaState extends State<EvolucaoMedidasAba> {
  EvolucaoMetrica _metrica = EvolucaoMetrica.peso;
  EvolucaoPeriodo _periodo = EvolucaoPeriodo.tudo;

  @override
  Widget build(BuildContext context) {
    final medidas = widget.medidas.where(evolucaoMedidaTemConteudo).toList();
    final disponiveis = [
      for (final m in EvolucaoMetrica.values)
        if (serieDaMetrica(medidas, m).isNotEmpty) m,
    ];
    if (disponiveis.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onAtualizar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FxEmptyState(
              key: const ValueKey('evolucao_medidas_empty'),
              icon: 'trend',
              title: ptS.evolucaoSemMedidaTitulo,
              subtitle: widget.vazioSubtitulo,
            ),
          ],
        ),
      );
    }
    final metrica =
        disponiveis.contains(_metrica) ? _metrica : disponiveis.first;
    final todos = serieDaMetrica(medidas, metrica);
    final pontos = pontosDoPeriodo(todos, _periodo);
    final recentes = medidasEmOrdem(medidas).reversed.toList();

    return RefreshIndicator(
      onRefresh: widget.onAtualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          96,
        ),
        children: [
          if (disponiveis.length > 1) ...[
            FxChoiceStrip<EvolucaoMetrica>(
              itens: [
                for (final m in disponiveis)
                  FxChoiceItem(value: m, label: m.rotulo),
              ],
              selecionado: metrica,
              onSelecionar: (m) => setState(() => _metrica = m),
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          _BlocoDaSerie(
            metrica: metrica,
            pontos: pontos,
            periodo: _periodo,
            onPeriodo: (p) => setState(() => _periodo = p),
            mostrarPeriodo: todos.length >= evolucaoPontosParaGrafico,
          ),
          const SizedBox(height: TokensStrip.s3),
          _GradeDeMetricas(
            medidas: medidas,
            metricas: disponiveis,
            selecionada: metrica,
            onSelecionar: (m) => setState(() => _metrica = m),
          ),
          const SizedBox(height: TokensStrip.s4),
          _Historico(medidas: recentes, onAbrir: widget.onAbrirMedida),
        ],
      ),
    );
  }
}

class _BlocoDaSerie extends StatelessWidget {
  const _BlocoDaSerie({
    required this.metrica,
    required this.pontos,
    required this.periodo,
    required this.onPeriodo,
    required this.mostrarPeriodo,
  });

  final EvolucaoMetrica metrica;
  final List<PontoGrafico> pontos;
  final EvolucaoPeriodo periodo;
  final ValueChanged<EvolucaoPeriodo> onPeriodo;
  final bool mostrarPeriodo;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final tendencia =
        metrica == EvolucaoMetrica.peso ? tendenciaDe(pontos) : const <double>[];
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mostrarPeriodo) ...[
            FxChoiceStrip<EvolucaoPeriodo>(
              itens: [
                for (final p in EvolucaoPeriodo.values)
                  FxChoiceItem(value: p, label: p.rotulo),
              ],
              selecionado: periodo,
              onSelecionar: onPeriodo,
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          if (pontos.length >= evolucaoPontosParaGrafico)
            FxGraficoLinha(
              pontos: pontos,
              unidade: metrica.unidade,
              tendencia: tendencia,
              resumo: resumoDaSerie(metrica, pontos),
            )
          else if (pontos.isEmpty)
            Text(
              ptS.evolucaoSemDadoNoPeriodo,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _Numero(
                    rotulo: ptS.evolucaoInicio(dataCurta(pontos.first.data)),
                    valor: '${formatBrDecimal(pontos.first.valor)} ${metrica.unidade}',
                  ),
                ),
                Expanded(
                  child: _Numero(
                    rotulo: ptS.evolucaoAtual(dataCurta(pontos.last.data)),
                    valor: '${formatBrDecimal(pontos.last.valor)} ${metrica.unidade}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(
              ptS.evolucaoFaltaParaLinha,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
          if (tendencia.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s2),
            Text(
              ptS.evolucaoLegendaTendencia,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: FocuxHubTypography.chip(chrome.mute)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: FocuxHubTypography.metric(
            color: chrome.ink,
            fontSize: FocuxHubTypography.metricLg,
          ),
        ),
      ],
    );
  }
}

class _GradeDeMetricas extends StatelessWidget {
  const _GradeDeMetricas({
    required this.medidas,
    required this.metricas,
    required this.selecionada,
    required this.onSelecionar,
  });

  final List<MedidaCorporal> medidas;
  final List<EvolucaoMetrica> metricas;
  final EvolucaoMetrica selecionada;
  final ValueChanged<EvolucaoMetrica> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final largura = (MediaQuery.sizeOf(context).width -
            FxSettingsLayout.pageInset * 2 -
            TokensStrip.s2) /
        2;
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        for (final m in metricas)
          SizedBox(
            width: largura,
            child: _CartaoDeMetrica(
              metrica: m,
              serie: serieDaMetrica(medidas, m),
              selecionada: m == selecionada,
              onTap: () => onSelecionar(m),
            ),
          ),
      ],
    );
  }
}

class _CartaoDeMetrica extends StatelessWidget {
  const _CartaoDeMetrica({
    required this.metrica,
    required this.serie,
    required this.selecionada,
    required this.onTap,
  });

  final EvolucaoMetrica metrica;
  final List<PontoGrafico> serie;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final diferenca = serie.last.valor - serie.first.valor;
    final valor = '${formatBrDecimal(serie.last.valor)} ${metrica.unidade}';
    return Semantics(
      button: true,
      selected: selecionada,
      label: '${metrica.rotulo}, $valor',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(
            context,
            accent: selecionada ? primary : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metrica.rotulo, style: FocuxHubTypography.chip(chrome.mute)),
              const SizedBox(height: 2),
              Text(
                valor,
                style: FocuxHubTypography.metric(
                  color: chrome.ink,
                  fontSize: FocuxHubTypography.metricMd,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                serie.length < 2
                    ? dataCurta(serie.last.data)
                    : diferencaTexto(diferenca, metrica.unidade),
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Historico extends StatelessWidget {
  const _Historico({required this.medidas, required this.onAbrir});

  /// Da mais nova para a mais antiga.
  final List<MedidaCorporal> medidas;
  final ValueChanged<MedidaCorporal>? onAbrir;

  static String _mes(String data) {
    final d = DateTime.tryParse(data);
    return d == null ? data : evolucaoMesAno(d);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final filhos = <Widget>[];
    String? mes;
    for (final m in medidas) {
      final atual = _mes(m.data);
      if (atual != mes) {
        mes = atual;
        filhos.add(
          Padding(
            padding: const EdgeInsets.only(
              top: TokensStrip.s2,
              bottom: TokensStrip.s1,
            ),
            child: Text(atual, style: FocuxHubTypography.chip(chrome.mute)),
          ),
        );
      }
      filhos.add(
        FxSatelliteListTile(
          title: evolucaoMedidaLabel(m),
          subtitle: Text(
            [
              evolucaoMedidaSubtitle(m),
              if (evolucaoAutorLabel(m.registradoPor) case final autor?) autor,
            ].join('\n'),
          ),
          onTap: onAbrir == null ? null : () => onAbrir!(m),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: filhos,
    );
  }
}
