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
import '../../../core/widgets/fx_link_row.dart';

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
    this.mostrarConfira = false,
  });

  /// Só o personal confere: o aviso "fora do comum" e o ícone na linha.
  final bool mostrarConfira;

  final List<MedidaCorporal> medidas;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;

  /// Linha do Histórico tocada.
  final ValueChanged<RegistroDoHistorico>? onAbrirRegistro;

  /// Quais linhas do Histórico abrem; padrão: as que têm medida.
  final bool Function(RegistroDoHistorico)? podeAbrirRegistro;

  /// Pendências de meta, acima do gráfico.
  final List<Widget> topo;

  /// Conquistas, depois das medidas.
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
    // Registros com "Está certo": o salto até eles não pede "Confira".
    final conferidas = datasConferidas(
      widget.medidas,
      gordura: widget.gordura,
      massa: widget.massa,
    );
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
              icon: FxIcons.grafico,
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
    final comPeriodo = serieCobreMaisQue(todos, 30);
    final pontos =
        comPeriodo ? pontosDoPeriodo(todos, _periodo) : todos;
    // Saltos sem "Está certo", um aviso só no topo (antes, um selo por linha).
    final saltos = <EvolucaoMetrica, List<PontoGrafico>>{
      if (widget.mostrarConfira)
        for (final m in disponiveis)
          if (_serie(medidas, m) case final serie
              when serie.length >= 2 &&
                  pontosSuspeitos(
                    serie,
                    m.unidade,
                    conferidas: conferidas,
                  ).contains(serie.length - 1))
            m: serie,
    };

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
          _BlocoDaSerie(
            conferidas: conferidas,
            metrica: metrica,
            pontos: pontos,
            periodo: comPeriodo ? _periodo : null,
            alvo: _metaDe(metrica)?.valorAlvo,
            onPeriodo: (p) => setState(() => _periodo = p),
            onVerRegistros: _abrirHistorico,
          ),
          const SizedBox(height: TokensStrip.s3),
          if (saltos.isNotEmpty) ...[
            EvolucaoAvisoConfira(
              quantidade: saltos.length,
              onTap:
                  () => _abrirHistorico(
                    destaque: {
                      for (final serie in saltos.values) ..._datasDoSalto(serie),
                    },
                  ),
            ),
            const SizedBox(height: TokensStrip.s2),
          ],
          _ListaDeMedidas(
            metricas: disponiveis,
            selecionada: metrica,
            serieDe: (m) => _serie(medidas, m),
            metaDe: _metaDe,
            suspeitas: saltos.keys.toSet(),
            onSelecionar: (m) => setState(() => _metrica = m),
          ),
          const SizedBox(height: TokensStrip.s4),
          ...widget.depois,
        ],
      ),
    );
  }
}

/// Aviso único de "Confira" no topo da lista (personal): abre o Histórico com
/// os registros a conferir marcados. Também usado no Comparar.
class EvolucaoAvisoConfira extends StatelessWidget {
  const EvolucaoAvisoConfira({
    super.key,
    required this.quantidade,
    required this.onTap,
  });

  final int quantidade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final alerta = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    final texto = ptS.evolucaoForaDoComum(quantidade);
    return Semantics(
      button: true,
      label: '$texto. ${ptS.evolucaoConferir}',
      excludeSemantics: true,
      child: Material(
        color: alerta.withValues(alpha: chrome.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensStrip.s3,
                vertical: TokensStrip.s2,
              ),
              child: Row(
                children: [
                  Icon(FxIcons.alertaPequeno, size: 18, color: alerta),
                  const SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: Text(
                      texto,
                      style: FocuxHubTypography.body(color: chrome.ink),
                    ),
                  ),
                  Text(
                    ptS.evolucaoConferir,
                    style: FocuxHubTypography.chip(alerta),
                  ),
                  Icon(FxIcons.chevronDireita, size: 16, color: alerta),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gráfico da medida escolhida: nome, valor atual, gráfico (com 2 dias ou mais)
/// e "Ver registros". Chips de período só quando a série passa de 30 dias.
class _BlocoDaSerie extends StatelessWidget {
  const _BlocoDaSerie({
    this.conferidas = const {},
    required this.metrica,
    required this.pontos,
    required this.periodo,
    required this.onPeriodo,
    required this.onVerRegistros,
    this.alvo,
  });

  final Set<String> conferidas;
  final EvolucaoMetrica metrica;
  final List<PontoGrafico> pontos;

  /// Nulo: a série é curta e os chips não mudariam nada.
  final EvolucaoPeriodo? periodo;
  final ValueChanged<EvolucaoPeriodo> onPeriodo;
  final VoidCallback onVerRegistros;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  metrica.rotulo,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
              ),
              if (pontos.isNotEmpty)
                Text(
                  formatBrComUnidade(pontos.last.valor, metrica.unidade),
                  style: FocuxHubTypography.cardTitle(color: chrome.ink)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
            ],
          ),
          if (periodo case final periodo?) ...[
            const SizedBox(height: TokensStrip.s2),
            FxChoiceStrip<EvolucaoPeriodo>(
              itens: [
                for (final p in EvolucaoPeriodo.values)
                  FxChoiceItem(value: p, label: p.rotulo),
              ],
              selecionado: periodo,
              onSelecionar: onPeriodo,
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          if (pontos.length == 1)
            // Um dia só não é série: valor e data, sem gráfico.
            Text(
              ptS.evolucaoRegistradoEm(dataCurta(pontos.single.data)),
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            )
          else if (pontos.length >= evolucaoPontosParaGrafico)
            RepaintBoundary(
              child: FxGraficoLinha(
                pontos: pontos,
                unidade: metrica.unidade,
                tendencia: tendencia,
                alvo: alvo,
                suspeitos: pontosSuspeitos(
                  pontos,
                  metrica.unidade,
                  conferidas: conferidas,
                ),
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
          const SizedBox(height: TokensStrip.s2),
          FxLinkRow(
            label: ptS.evolucaoVerRegistros,
            icon: FxIcons.historico,
            onTap: onVerRegistros,
          ),
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
    this.suspeitas = const {},
  });

  final List<EvolucaoMetrica> metricas;
  final EvolucaoMetrica selecionada;
  final List<PontoGrafico> Function(EvolucaoMetrica) serieDe;
  final MetaCorporal? Function(EvolucaoMetrica) metaDe;
  final ValueChanged<EvolucaoMetrica> onSelecionar;

  /// Medidas com salto sem "Está certo": ícone de alerta ao lado do valor.
  final Set<EvolucaoMetrica> suspeitas;

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
              suspeita: suspeitas.contains(m),
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

  /// Última mudança fora do comum: ícone de alerta (o aviso fica no topo).
  final bool suspeita;

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
                      // Linha na altura normal: o "Confira" é o aviso do topo.
                    ],
                  ),
                  if (suspeita) ...[
                    const SizedBox(width: TokensStrip.s1),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(FxIcons.alertaPequeno, size: 16, color: alerta),
                    ),
                  ],
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

