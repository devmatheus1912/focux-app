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
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../data/meta_corporal.dart';
import '../utils/evolucao_display.dart';
import '../utils/evolucao_series.dart';
import 'evolucao_historico_folha.dart';
import '../../../core/theme/fx_icons.dart';

/// Aba Medidas, igual para personal e aluno. A linha abre [onAbrirMedida].
class EvolucaoMedidasAba extends StatefulWidget {
  const EvolucaoMedidasAba({
    super.key,
    required this.medidas,
    required this.vazioSubtitulo,
    required this.onAtualizar,
    this.onAbrirRegistro,
    this.podeAbrirRegistro,
    this.topo = const [],
    this.depois = const [],
    this.metas = const [],
    this.gordura = const [],
    this.massa = const [],
  });

  final List<MedidaCorporal> medidas;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;

  /// Linha do Histórico tocada.
  final ValueChanged<RegistroDoHistorico>? onAbrirRegistro;

  /// Quais linhas do Histórico abrem; padrão: as que têm medida.
  final bool Function(RegistroDoHistorico)? podeAbrirRegistro;

  /// Pendências de meta, acima do gráfico.
  final List<Widget> topo;

  /// Conquistas, entre as medidas e o histórico.
  final List<Widget> depois;
  final List<MetaCorporal> metas;

  /// Gordura e massa magra vêm das avaliações.
  final List<PontoGordura> gordura;
  final List<PontoGordura> massa;

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

  List<RegistroDoHistorico> get _registros => registrosDoHistorico(
    widget.medidas.where(evolucaoMedidaTemConteudo).toList(),
    gordura: widget.gordura,
    massa: widget.massa,
  );

  bool _podeAbrir(RegistroDoHistorico r) =>
      widget.onAbrirRegistro != null &&
      (widget.podeAbrirRegistro?.call(r) ?? r.medida != null);

  /// Histórico com [destaque] marcado (o par do "Confira").
  Future<void> _abrirHistorico({Set<String> destaque = const {}}) async {
    final r = await abrirHistoricoDaEvolucao(
      context,
      registros: _registros,
      destaque: destaque,
      podeAbrir: _podeAbrir,
    );
    if (r != null) widget.onAbrirRegistro?.call(r);
  }

  /// O salto que pede "Confira": a data de antes e a de depois.
  Set<String> _datasDoSalto(List<PontoGrafico> serie) {
    final i = serie.length - 1;
    String iso(DateTime d) => d.toIso8601String().substring(0, 10);
    return {iso(serie[i - 1].data), iso(serie[i].data)};
  }

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
    final registros = _registros;

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
            onConfira: (serie) => _abrirHistorico(destaque: _datasDoSalto(serie)),
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
          FxSatelliteListTile(
            title: ptS.evolucaoHistoricoLinha(registros.length),
            titleCase: false,
            onTap: _abrirHistorico,
          ),
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
                suspeitos: pontosSuspeitos(pontos, metrica.unidade),
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
    required this.onConfira,
  });

  final List<EvolucaoMetrica> metricas;
  final EvolucaoMetrica selecionada;
  final List<PontoGrafico> Function(EvolucaoMetrica) serieDe;
  final MetaCorporal? Function(EvolucaoMetrica) metaDe;
  final ValueChanged<EvolucaoMetrica> onSelecionar;
  final ValueChanged<List<PontoGrafico>> onConfira;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final series = {for (final m in metricas) m: serieDe(m)};
    // Data mais antiga da lista: quem começou depois diz "desde a 1ª medida".
    final inicio = series.values
        .map((s) => s.first.data)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return Container(
      decoration: fxListCardDecoration(context),
      child: Column(
        children: [
          for (final (i, m) in metricas.indexed) ...[
            if (i > 0) Divider(height: 1, color: chrome.line),
            _LinhaDeMetrica(
              metrica: m,
              serie: series[m]!,
              meta: metaDe(m),
              selecionada: m == selecionada,
              basePropria: series[m]!.first.data.isAfter(inicio),
              suspeita:
                  series[m]!.length >= 2 &&
                  pontosSuspeitos(series[m]!, m.unidade).contains(series[m]!.length - 1),
              onTap: () => onSelecionar(m),
              onConfira: () => onConfira(series[m]!),
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
    required this.onConfira,
    this.meta,
    this.basePropria = false,
    this.suspeita = false,
  });

  final EvolucaoMetrica metrica;
  final List<PontoGrafico> serie;
  final bool selecionada;
  final VoidCallback onTap;
  final MetaCorporal? meta;

  /// Começou depois das outras medidas: a base da diferença é outra data.
  final bool basePropria;

  /// Última mudança fora do comum: selo "Confira", que abre o Histórico.
  final bool suspeita;
  final VoidCallback onConfira;

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
            : basePropria
            ? ptS.evolucaoDesdePrimeira(
              diferencaTexto(diferenca, metrica.unidade),
              dataCurta(serie.first.data),
            )
            : ptS.evolucaoDesde(
              diferencaTexto(diferenca, metrica.unidade),
              dataCurta(serie.first.data),
            );
    final alerta = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
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
      label: [
        metrica.rotulo,
        valor,
        detalhe,
        if (rumoTexto != null) rumoTexto,
        if (suspeita) ptS.comparacaoConfira,
      ].join(', '),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        valor,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      if (suspeita)
                        // Alvo de toque próprio: a linha troca o gráfico, o selo
                        // abre o registro para conferir.
                        InkWell(
                          onTap: onConfira,
                          borderRadius: BorderRadius.circular(TokensStrip.s2),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(FxIcons.alertaPequeno, size: 14, color: alerta),
                                const SizedBox(width: 2),
                                Text(ptS.comparacaoConfira, style: FocuxHubTypography.chip(alerta)),
                              ],
                            ),
                          ),
                        ),
                    ],
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

