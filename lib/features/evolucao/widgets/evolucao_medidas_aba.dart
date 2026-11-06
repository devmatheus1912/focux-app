import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_grafico_linha.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../data/meta_corporal.dart';
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
    this.topo = const [],
    this.depois = const [],
    this.metas = const [],
    this.gordura = const [],
  });

  final List<MedidaCorporal> medidas;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;
  final ValueChanged<MedidaCorporal>? onAbrirMedida;

  /// Pendências de meta, acima do gráfico.
  final List<Widget> topo;

  /// Conquistas, entre as medidas e o histórico.
  final List<Widget> depois;
  final List<MetaCorporal> metas;

  /// Gordura vem das avaliações.
  final List<PontoGordura> gordura;

  @override
  State<EvolucaoMedidasAba> createState() => _EvolucaoMedidasAbaState();
}

class _EvolucaoMedidasAbaState extends State<EvolucaoMedidasAba> {
  EvolucaoMetrica _metrica = EvolucaoMetrica.peso;
  EvolucaoPeriodo _periodo = EvolucaoPeriodo.tudo;

  List<PontoGrafico> _serie(List<MedidaCorporal> medidas, EvolucaoMetrica m) =>
      m == EvolucaoMetrica.gordura
          ? serieDeGordura(widget.gordura)
          : serieDaMetrica(medidas, m);

  MetaCorporal? _metaDe(EvolucaoMetrica m) =>
      widget.metas.where((x) => x.aberta && x.metrica == m.codigoMeta).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final medidas = widget.medidas.where(evolucaoMedidaTemConteudo).toList();
    final disponiveis = [
      for (final m in EvolucaoMetrica.values)
        if (_serie(medidas, m).isNotEmpty) m,
    ];
    if (disponiveis.isEmpty) {
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
            ...widget.topo,
            ...widget.depois,
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
    final todos = _serie(medidas, metrica);
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
          ...widget.topo,
          if (todos.length >= evolucaoPontosParaGrafico) ...[
            _BlocoDaSerie(
              metrica: metrica,
              pontos: pontos,
              periodo: _periodo,
              alvo: _metaDe(metrica)?.valorAlvo,
              onPeriodo: (p) => setState(() => _periodo = p),
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          _ListaDeMedidas(
            metricas: disponiveis,
            selecionada: metrica,
            serieDe: (m) => _serie(medidas, m),
            metaDe: _metaDe,
            onSelecionar: (m) => setState(() => _metrica = m),
          ),
          // Trocar o gráfico tocando na linha não se descobre sozinho.
          if (disponiveis.length > 1 && todos.length >= evolucaoPontosParaGrafico)
            Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Text(
                ptS.evolucaoToqueParaGrafico,
                style: FocuxHubTypography.bodyMuted(
                  color: ShellChrome.of(context).mute,
                ),
              ),
            ),
          const SizedBox(height: TokensStrip.s4),
          ...widget.depois,
          _LinhaHistorico(medidas: recentes, onAbrir: widget.onAbrirMedida),
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
    this.alvo,
  });

  final EvolucaoMetrica metrica;
  final List<PontoGrafico> pontos;
  final EvolucaoPeriodo periodo;
  final ValueChanged<EvolucaoPeriodo> onPeriodo;
  final double? alvo;

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
          Text(
            metrica.rotulo,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s2),
          FxChoiceStrip<EvolucaoPeriodo>(
            itens: [
              for (final p in EvolucaoPeriodo.values)
                FxChoiceItem(value: p, label: p.rotulo),
            ],
            selecionado: periodo,
            onSelecionar: onPeriodo,
          ),
          const SizedBox(height: TokensStrip.s3),
          if (pontos.length >= evolucaoPontosParaGrafico)
            RepaintBoundary(
              child: FxGraficoLinha(
                pontos: pontos,
                unidade: metrica.unidade,
                tendencia: tendencia,
                alvo: alvo,
                resumo: resumoDaSerie(metrica, pontos),
              ),
            )
          else
            Text(
              ptS.evolucaoSemDadoNoPeriodo,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
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

/// Uma linha por medida, com divisor. Toque troca o gráfico.
class _ListaDeMedidas extends StatelessWidget {
  const _ListaDeMedidas({
    required this.metricas,
    required this.selecionada,
    required this.serieDe,
    required this.metaDe,
    required this.onSelecionar,
  });

  final List<EvolucaoMetrica> metricas;
  final EvolucaoMetrica selecionada;
  final List<PontoGrafico> Function(EvolucaoMetrica) serieDe;
  final MetaCorporal? Function(EvolucaoMetrica) metaDe;
  final ValueChanged<EvolucaoMetrica> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      decoration: fxListCardDecoration(context),
      child: Column(
        children: [
          for (final (i, m) in metricas.indexed) ...[
            if (i > 0) Divider(height: 1, color: chrome.line),
            _LinhaDeMetrica(
              metrica: m,
              serie: serieDe(m),
              meta: metaDe(m),
              selecionada: m == selecionada,
              onTap: () => onSelecionar(m),
            ),
          ],
        ],
      ),
    );
  }
}

/// Valor, diferença e, com meta, a barra até o alvo.
class _LinhaDeMetrica extends StatelessWidget {
  const _LinhaDeMetrica({
    required this.metrica,
    required this.serie,
    required this.selecionada,
    required this.onTap,
    this.meta,
  });

  final EvolucaoMetrica metrica;
  final List<PontoGrafico> serie;
  final bool selecionada;
  final VoidCallback onTap;
  final MetaCorporal? meta;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final valor = '${formatBrDecimal(serie.last.valor)} ${metrica.unidade}';
    final meta = this.meta;
    final diferenca = serie.last.valor - serie.first.valor;
    // A diferença diz a base: "+20,0 cm desde 30/10", não um número solto.
    final detalhe =
        serie.length < 2
            ? dataCurta(serie.last.data)
            : ptS.evolucaoDesde(
              diferencaTexto(diferenca, metrica.unidade),
              dataCurta(serie.first.data),
            );
    final rumo = rumoDaMeta(meta, serie.last.valor);
    final corRumo = corDoRumo(chrome, rumo);
    final rumoTexto = switch (rumo) {
      RumoDaMeta.noRumo => ptS.evolucaoNoRumo,
      RumoDaMeta.seAfastando => ptS.evolucaoSeAfastando,
      null => null,
    };
    return Semantics(
      button: true,
      selected: selecionada,
      label: [metrica.rotulo, valor, detalhe, if (rumoTexto != null) rumoTexto].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          color: selecionada ? primary.withValues(alpha: 0.07) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Valor no tamanho do título do cartão: a linha é para varrer,
              // o número grande fica para o gráfico.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metrica.rotulo,
                          style: FocuxHubTypography.cardTitle(
                            color: selecionada ? primary : chrome.ink,
                          ),
                        ),
                        Text(
                          detalhe,
                          style: FocuxHubTypography.bodyMuted(color: chrome.mute)
                              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                        if (rumoTexto != null)
                          Text(
                            rumoTexto,
                            style: FocuxHubTypography.chip(corRumo ?? chrome.mute),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  Text(
                    valor,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink)
                        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              if (meta != null) ...[
                const SizedBox(height: TokensStrip.s2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.s1),
                  child: LinearProgressIndicator(
                    value: fracaoAteOAlvo(
                      meta.valorInicial,
                      meta.valorAlvo,
                      serie.last.valor,
                    ),
                    minHeight: 6,
                    color: primary,
                    // Na linha selecionada o fundo já é primary a 7%: o trilho
                    // em `line` sumia e meta em 0% parecia sem barra. Se
                    // afastando, o trilho fica na cor de alerta.
                    backgroundColor:
                        rumo == RumoDaMeta.seAfastando
                            ? corRumo!.withValues(alpha: 0.28)
                            : selecionada
                            ? primary.withValues(alpha: 0.18)
                            : chrome.line,
                  ),
                ),
                const SizedBox(height: TokensStrip.s1),
                Text(
                  ptS.evolucaoAlvoDe(
                    '${formatBrDecimal(meta.valorAlvo)} ${metrica.unidade}',
                  ),
                  textAlign: TextAlign.end,
                  style: FocuxHubTypography.chip(chrome.mute),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Verde no rumo, âmbar se afastando; nulo sem meta.
Color? corDoRumo(ShellPalette chrome, RumoDaMeta? rumo) => switch (rumo) {
  RumoDaMeta.noRumo => chrome.isDark ? EagleTokens.goodDark : EagleTokens.good,
  RumoDaMeta.seAfastando => chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn,
  null => null,
};

/// O histórico mora numa folha: a aba mostra gráfico e medidas sem cartões de data.
class _LinhaHistorico extends StatelessWidget {
  const _LinhaHistorico({required this.medidas, required this.onAbrir});

  /// Da mais nova para a mais antiga.
  final List<MedidaCorporal> medidas;
  final ValueChanged<MedidaCorporal>? onAbrir;

  Future<void> _abrir(BuildContext context) async {
    final escolhida = await showFxHomeSheet<MedidaCorporal>(
      context,
      builder: (ctx) => _FolhaHistorico(medidas: medidas, podeAbrir: onAbrir != null),
    );
    if (escolhida != null) onAbrir?.call(escolhida);
  }

  @override
  Widget build(BuildContext context) => FxSatelliteListTile(
    title: ptS.evolucaoHistoricoLinha(medidas.length),
    titleCase: false,
    onTap: () => _abrir(context),
  );
}

class _FolhaHistorico extends StatelessWidget {
  const _FolhaHistorico({required this.medidas, required this.podeAbrir});

  final List<MedidaCorporal> medidas;
  final bool podeAbrir;

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
          onTap: podeAbrir ? () => Navigator.of(context).pop(m) : null,
        ),
      );
    }
    return FxHomeSheetSurface(
      isDark: chrome.isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: chrome.isDark),
          const SizedBox(height: TokensStrip.s3),
          FxHomeSheetHeader(
            isDark: chrome.isDark,
            title: ptS.evolucaoHistoricoTitulo,
          ),
          const SizedBox(height: TokensStrip.s2),
          Flexible(child: ListView(shrinkWrap: true, children: filhos)),
        ],
      ),
    );
  }
}
