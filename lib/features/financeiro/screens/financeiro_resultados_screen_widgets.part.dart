part of 'financeiro_resultados_screen.dart';

class _EvolucaoChart extends StatelessWidget {
  final List<EvolucaoMensalItem> items;
  final bool isDark;
  const _EvolucaoChart({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final primaryDeep = BrandPalette.deep(primary);
    final primaryAccent = BrandPalette.accent(primary);

    final maxV = items.map((e) => e.recebido.cents).reduce(math.max);
    final chartMax = maxV <= 0 ? 10000.0 : maxV.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s4,
          TokensStrip.s4,
          TokensStrip.s3,
        ),
        decoration: fxListCardDecoration(
          context,
          accent: primary,
          radius: FxSettingsLayout.groupRadius,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    'Evolução · 6 meses',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.body(
                      color: ink,
                    ).copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
                  ),
                ),
                const SizedBox(width: TokensStrip.s2),
                if (items.length > 1)
                  Builder(
                    builder: (_) {
                      final prev = items[items.length - 2].recebido;
                      final curr = items.last.recebido;
                      if (prev.isPositive) {
                        final diff =
                            ((curr.cents - prev.cents) / prev.cents * 100)
                                .round();
                        final sign = diff > 0 ? '+' : '';
                        return Text(
                          '$sign$diff% vs ${items[items.length - 2].mes.substring(5)}',
                          style: FocuxHubTypography.chip(mute),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            const SizedBox(height: TokensStrip.s4),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children:
                    items.asMap().entries.map((e) {
                      final isLast = e.key == items.length - 1;
                      final h = (e.value.recebido.cents / chartMax).clamp(
                        0.05,
                        1.0,
                      );

                      final mes = e.value.mes;
                      final label = mes.length >= 7 ? mes.substring(5) : mes;

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${formatBrDecimal(e.value.recebido.cents / 100000)}k',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isLast ? ink : mute,
                                fontWeight:
                                    isLast ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: h,
                                  widthFactor: 0.7,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                        bottom: Radius.circular(2),
                                      ),
                                      gradient:
                                          isLast
                                              ? LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors:
                                                    isDark
                                                        ? [
                                                          primaryAccent,
                                                          primary,
                                                        ]
                                                        : [
                                                          primary,
                                                          primaryDeep,
                                                        ],
                                              )
                                              : null,
                                      color:
                                          !isLast
                                              ? (isDark
                                                  ? mute.withValues(alpha: 0.22)
                                                  : primarySoft)
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s1),
                            Text(
                              label,
                              style: FocuxHubTypography.chip(
                                isLast ? ink : mute,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

/// "Outubro 2026 ▾": o mês que os blocos abaixo mostram.
class _SeletorDeMes extends StatelessWidget {
  const _SeletorDeMes({required this.rotulo, required this.onTap});

  final String rotulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FxActionChip(
          label: rotulo,
          accent: Theme.of(context).colorScheme.primary,
          isDark: Theme.of(context).brightness == Brightness.dark,
          onPressed: onTap,
        ),
      ),
    );
  }
}

/// Cartão com um rótulo, um número grande e linhas de apoio.
class _BlocoNumero extends StatelessWidget {
  const _BlocoNumero({
    required this.rotulo,
    required this.valor,
    required this.apoio,
    this.destaque = false,
  });

  final String rotulo;
  final String valor;
  final List<String> apoio;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FxSettingsLayout.pageInset,
      ),
      child: FxStripCard(
        emphasize: destaque,
        padding: const EdgeInsets.all(TokensStrip.s3),
        semanticsLabel: '$rotulo $valor. ${apoio.join('. ')}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: FocuxHubTypography.chip(mute)),
            const SizedBox(height: 6),
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
            for (final linha in apoio) ...[
              const SizedBox(height: 4),
              Text(linha, style: FocuxHubTypography.bodyMuted(color: mute)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlocoQuantoEntrou extends StatelessWidget {
  const _BlocoQuantoEntrou({required this.resumo});

  final ResumoMensal resumo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _BlocoNumero(
      rotulo: s.resultadosQuantoEntrou,
      valor: resumo.totalRecebido.formatCompact(),
      destaque: true,
      apoio: [
        if (resumo.recebidoDeMesesAnteriores.isPositive)
          s.financeiroDeMesesAnteriores(
            resumo.recebidoDeMesesAnteriores.formatCompact(),
          ),
      ],
    );
  }
}

class _BlocoLancado extends StatelessWidget {
  const _BlocoLancado({required this.resumo});

  final ResumoMensal resumo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _BlocoNumero(
      rotulo: s.resultadosLancado,
      valor: resumo.totalPrevisto.formatCompact(),
      apoio: [
        if (resumo.totalEmAberto.isPositive)
          s.resultadosAindaEmAberto(resumo.totalEmAberto.formatCompact()),
        if (resultadosRecebidoMaiorQueLancado(resumo))
          s.resultadosExplicaRecebido,
      ],
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
