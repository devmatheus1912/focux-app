part of 'financeiro_resultados_screen.dart';

/// Recebido de 6 meses. O mês na tela fica em destaque; tocar numa barra vai
/// para aquele mês.
class _EvolucaoChart extends StatelessWidget {
  const _EvolucaoChart({
    required this.items,
    required this.isDark,
    required this.ano,
    required this.mes,
    required this.onMes,
  });

  final List<EvolucaoMensalItem> items;
  final bool isDark;
  final int ano;
  final int mes;
  final void Function(int ano, int mes) onMes;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final trilho = BrandPalette.soft(primary, dark: isDark);
    final maxV = items.map((e) => e.recebido.cents).reduce(math.max);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.of(context).resultadosEvolucao,
              style: FocuxHubTypography.cardTitle(color: ink),
            ),
            const SizedBox(height: TokensStrip.s3),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in items)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final m = resultadosMesDoItem(item.mes);
                          final selecionado = m?.ano == ano && m?.mes == mes;
                          final valor = item.recebido.cents;
                          final altura = maxV <= 0 ? 0.0 : valor / maxV;
                          final nome = m == null
                              ? item.mes
                              : financeiroMesCurto(m.mes);
                          return Semantics(
                            button: m != null,
                            selected: selecionado,
                            label: '$nome, ${item.recebido.formatCompact()}',
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: m == null ? null : () => onMes(m.ano, m.mes),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (selecionado)
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        item.recebido.formatCompact(),
                                        maxLines: 1,
                                        style: FocuxHubTypography.bodyMuted(
                                          color: ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: TokensStrip.s1),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: altura,
                                        widthFactor: 0.7,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: selecionado ? primary : trilho,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: TokensStrip.s1),
                                  Text(
                                    nome,
                                    style: FocuxHubTypography.bodyMuted(
                                      color: selecionado ? ink : mute,
                                      fontWeight:
                                          selecionado
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceiroVencimentosGroup extends StatelessWidget {
  const _FinanceiroVencimentosGroup({required this.items});

  final List<VencimentoItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Vencimentos',
            actionLabel: items.length > 3 ? 'Ver todos' : null,
            onAction:
                items.length > 3
                    ? () => _openMensalidades(context, source: 'vencimentos')
                    : null,
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            'Cobre em Mensalidades.',
            style: FocuxHubTypography.bodyMuted(
              color: fxScreenMute(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          for (final item in items.take(3))
            FxSatelliteListTile(
              title: item.alunoNome,
              subtitle: Text(_vencimentoSubtitle(item)),
              trailing: Text(
                item.valor.formatCobranca(),
                style: FocuxHubTypography.bodyMuted(
                  color:
                      item.status == 'ATRASADO'
                          ? EagleTokens.bad
                          : fxScreenMute(context),
                  fontWeight: FontWeight.w700,
                ).copyWith(
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              accent: item.status == 'ATRASADO' ? EagleTokens.bad : null,
              onTap:
                  () => _openAlunoOrMensalidades(
                    context,
                    item.alunoId,
                    source: 'vencimento',
                  ),
            ),
        ],
      ),
    );
  }

  String _vencimentoSubtitle(VencimentoItem item) =>
      financeiroVencimentoDashboardSubtitle(
        mesReferencia: item.mesReferencia,
        vencimento: item.vencimento,
        status: item.status,
      );
}

class _FinanceiroTopAlunosGroup extends StatelessWidget {
  const _FinanceiroTopAlunosGroup({required this.items});

  final List<TopAlunoItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(3).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Top alunos · acumulado',
            actionLabel: items.length > 3 ? 'Ver todos' : null,
            onAction:
                items.length > 3
                    ? () => _openMensalidades(context, source: 'top')
                    : null,
          ),
          const SizedBox(height: TokensStrip.s3),
          for (var i = 0; i < visible.length; i++)
            FxSatelliteListTile(
              title: visible[i].alunoNome,
              subtitle: Text('#${i + 1}'),
              trailing: Text(
                visible[i].totalPago.formatCobranca(),
                style: FocuxHubTypography.bodyMuted(
                  color: fxScreenMute(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap:
                  () => _openAlunoOrMensalidades(
                    context,
                    visible[i].alunoId,
                    source: 'top',
                  ),
            ),
        ],
      ),
    );
  }
}

void _openMensalidades(BuildContext context, {String source = 'hub'}) {
  FinanceiroHubScope.maybeOf(context)?.goToMensalidades(source: source);
}

void _openAlunoOrMensalidades(
  BuildContext context,
  int? alunoId, {
  String source = 'hub',
}) {
  if (alunoId != null) {
    AnalyticsService.instance.track(
      ProductEvents.financeiroMensalidadesOpened,
      props: {'source': source, 'alunoId': alunoId},
    );
    context.push('/financeiro?alunoId=$alunoId');
    return;
  }
  _openMensalidades(context, source: source);
}

/// ‹ Outubro 2026 ›: o mês que os blocos abaixo mostram.
class _SeletorDeMes extends StatelessWidget {
  const _SeletorDeMes({
    required this.rotulo,
    required this.onTap,
    required this.onAnterior,
    required this.onProximo,
  });

  final String rotulo;
  final VoidCallback onTap;
  final VoidCallback onAnterior;

  /// Nulo no mês atual: não há mês futuro aqui.
  final VoidCallback? onProximo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s2,
        vertical: TokensStrip.s2,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: s.agendaMesAnterior,
            onPressed: onAnterior,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: FxActionChip(
                label: rotulo,
                accent: Theme.of(context).colorScheme.primary,
                isDark: Theme.of(context).brightness == Brightness.dark,
                onPressed: onTap,
              ),
            ),
          ),
          IconButton(
            tooltip: s.agendaProximoMes,
            onPressed: onProximo,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Destaque do mês: o que entrou, sobre o que foi lançado.
class _BlocoQuantoEntrou extends StatelessWidget {
  const _BlocoQuantoEntrou({required this.resumo, this.variacaoPct});

  final ResumoMensal resumo;
  final int? variacaoPct;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);
    final primary = Theme.of(context).colorScheme.primary;
    final variacao = variacaoPct;
    final apoio = [
      s.resultadosDeLancado(resumo.totalPrevisto.formatCompact()),
      if (resumo.totalEmAberto.isPositive)
        s.resultadosAReceber(resumo.totalEmAberto.formatCompact()),
      if (variacao != null)
        s.resultadosVariacao('${variacao > 0 ? '+' : ''}$variacao'),
      if (resumo.recebidoDeMesesAnteriores.isPositive)
        s.financeiroDeMesesAnteriores(
          resumo.recebidoDeMesesAnteriores.formatCompact(),
        ),
      if (resultadosRecebidoMaiorQueLancado(resumo)) s.resultadosExplicaRecebido,
    ];
    final valor = resumo.totalRecebido.formatCompact();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: FxStripCard(
        emphasize: true,
        padding: const EdgeInsets.all(TokensStrip.s3),
        semanticsLabel: '${s.resultadosQuantoEntrou} $valor. ${apoio.join('. ')}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.resultadosQuantoEntrou,
              style: FocuxHubTypography.chip(mute),
            ),
            const SizedBox(height: TokensStrip.s1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: FocuxHubTypography.kpi(
                  color: ink,
                  fontSize: FocuxHubTypography.metricLg,
                ).copyWith(
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
            ClipRRect(
              borderRadius: BorderRadius.circular(TokensStrip.s1),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: resultadosProgresso(resumo),
                color: primary,
                backgroundColor: primary.withValues(alpha: 0.12),
              ),
            ),
            for (final linha in apoio) ...[
              const SizedBox(height: TokensStrip.s1),
              Text(linha, style: FocuxHubTypography.bodyMuted(color: mute)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlocoQuemAtrasa extends StatelessWidget {
  const _BlocoQuemAtrasa({required this.resumo, required this.onTap});

  final ResumoMensal resumo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final atrasa = resumo.quantidadeAtrasadas > 0;
    final alunos = s.resultadosAtrasaAlunos(resumo.inadimplentes);
    final valor = s.resultadosAtrasaValor(resumo.totalAtrasado.formatCompact());
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: FxSatelliteListTile(
        title: s.resultadosQuemAtrasa,
        titleCase: false,
        subtitle: Text(atrasa ? '$alunos · $valor' : s.resultadosAtrasaAlunos(0)),
        accent: atrasa ? EagleTokens.bad : null,
        onTap: atrasa ? onTap : null,
      ),
    );
  }
}

/// "Detalhes": números de coorte, recolhidos e só com base suficiente.
class _SecaoDetalhes extends StatelessWidget {
  const _SecaoDetalhes({
    required this.coorte,
    required this.abertos,
    required this.onAlternar,
    required this.onExplicar,
    required this.isDark,
  });

  final BusinessSnapshot coorte;
  final bool abertos;
  final VoidCallback onAlternar;
  final void Function(String titulo, String texto) onExplicar;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final visiveis = resultadosDetalhesVisiveis(
      pagantes: coorte.alunosPagantes,
      mesesComCobranca: coorte.mesesComCobranca,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: s.resultadosDetalhes),
          const SizedBox(height: TokensStrip.s2),
          if (!visiveis)
            Text(
              s.resultadosPoucosDados(resultadosMinPagantes, resultadosMinMeses),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionChip(
                label: abertos
                    ? s.resultadosDetalhesFechar
                    : s.resultadosDetalhesAbrir,
                accent: primary,
                isDark: isDark,
                onPressed: onAlternar,
              ),
            ),
            if (abertos) ...[
              const SizedBox(height: TokensStrip.s3),
              OperationalMetricTile(
                label: s.resultadosNdr,
                value: resultadosPct(coorte.ndrPct),
                hint: s.resultadosNdrHint,
                onInfo: () => onExplicar(s.resultadosNdr, s.resultadosNdrAjuda),
                color: primary,
                isDark: isDark,
              ),
              const SizedBox(height: TokensStrip.s2),
              OperationalMetricTile(
                label: s.resultadosArpa,
                value: formatBrlCurrency(coorte.arpa),
                hint: s.resultadosArpaHint(coorte.alunosPagantes),
                onInfo: () =>
                    onExplicar(s.resultadosArpa, s.resultadosArpaAjuda),
                color: primary,
                isDark: isDark,
              ),
              const SizedBox(height: TokensStrip.s2),
              OperationalMetricTile(
                label: s.resultadosLtv,
                value: formatBrlCurrency(coorte.ltvProxy),
                hint: s.resultadosLtvHint(
                  resultadosMesesLabel(coorte.vidaMediaMeses),
                ),
                onInfo: () => onExplicar(s.resultadosLtv, s.resultadosLtvAjuda),
                color: primary,
                isDark: isDark,
              ),
              const SizedBox(height: TokensStrip.s2),
              OperationalMetricTile(
                label: s.resultadosChurn,
                value: resultadosPct(coorte.churnPct),
                hint: s.resultadosChurnHint,
                onInfo: () =>
                    onExplicar(s.resultadosChurn, s.resultadosChurnAjuda),
                color: primary,
                isDark: isDark,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
