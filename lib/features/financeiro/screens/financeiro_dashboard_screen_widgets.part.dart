part of 'financeiro_dashboard_screen.dart';

class _FinanceiroKpiGroup extends StatelessWidget {
  const _FinanceiroKpiGroup({required this.data});

  final FinanceiroDashboard data;

  @override
  Widget build(BuildContext context) {
    final mes = DashboardHomeSnapshot.monthNames[DateTime.now().month - 1];
    final pendente = math.max(0.0, data.previsaoReceita - data.receitaMes);
    final progressRaw =
        data.previsaoReceita > 0 ? data.receitaMes / data.previsaoReceita : 0.0;
    final metaSuperada =
        data.previsaoReceita > 0 && data.receitaMes >= data.previsaoReceita;
    final recebido = formatBrlCurrency(data.receitaMes, showDecimals: false);
    final pendenteLabel = formatBrlCurrency(pendente, showDecimals: false);
    final metaLabel = financePercentLabel(
      progressRaw,
      exceeded: metaSuperada,
    );
    final showTicket = data.receitaMes > 0 && data.ticketMedio > 0;
    final inadimpl = data.totalInadimplentes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FxSettingsLayout.pageInset),
      child: Semantics(
        label:
            'Panorama financeiro de $mes. '
            'Recebido $recebido. Pendente $pendenteLabel. $metaLabel',
        child: FxSettingsGroup(
          children: [
            FxSettingsTile(
              fxIcon: 'dollar-sign',
              label: 'Recebido · $mes',
              subtitle: metaSuperada
                  ? 'Meta superada'
                  : pendente > 0
                      ? 'Faltam $pendenteLabel para a meta'
                      : 'Meta do mês sob controle',
              value: recebido,
              numeric: true,
              showDivider: true,
              onTap: () => _openMensalidades(context, source: 'kpi'),
            ),
            FxSettingsTile(
              fxIcon: 'alert-triangle',
              label: 'Pendente',
              subtitle: inadimpl > 0
                  ? '$inadimpl ${financeInadimplLabel(MediaQuery.sizeOf(context).width).toLowerCase()}'
                  : 'Sem inadimplência no recorte',
              value: pendenteLabel,
              numeric: true,
              showDivider: true,
              onTap: () => _openMensalidades(context, source: 'kpi'),
            ),
            FxSettingsTile(
              fxIcon: 'target',
              label: 'Meta',
              subtitle: showTicket
                  ? 'Ticket ${formatBrlCurrency(data.ticketMedio, showDecimals: false)}'
                  : null,
              value: metaLabel,
              showDivider: false,
              onTap: () => _openMensalidades(context, source: 'kpi'),
            ),
          ],
        ),
      ),
    );
  }
}

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

    final maxV = items.map((e) => e.recebido).reduce(math.max);
    final chartMax = maxV <= 0 ? 100.0 : maxV;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FxSettingsLayout.pageInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 18, 16, 14),
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
                Text(
                  'Evolução · 6 meses',
                  style: FocuxHubTypography.body(color: ink).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (items.length > 1)
                  Builder(
                    builder: (_) {
                      final prev = items[items.length - 2].recebido;
                      final curr = items.last.recebido;
                      if (prev > 0) {
                        final diff = ((curr - prev) / prev * 100).round();
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
                      final h = (e.value.recebido / chartMax).clamp(0.05, 1.0);

                      final mes = e.value.mes;
                      final label =
                          mes.length >= 7 ? mes.substring(5) : mes;

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${(e.value.recebido / 1000).toStringAsFixed(1)}k',
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
                                                  ? dashboardHeroMutedOnTeal()
                                                      .withValues(alpha: 0.08)
                                                  : primarySoft)
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isLast ? ink : mute,
                                fontWeight:
                                    isLast ? FontWeight.w600 : FontWeight.w500,
                                letterSpacing: 0.4,
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
      padding: const EdgeInsets.symmetric(horizontal: FxSettingsLayout.pageInset),
      child: FxSettingsGroup(
        header: 'Vencimentos',
        caption: 'Cobre em Mensalidades.',
        children: [
          for (var i = 0; i < items.length; i++)
            FxSettingsTile(
              fxIcon: items[i].status == 'ATRASADO'
                  ? 'alert-triangle'
                  : 'clock',
              label: items[i].alunoNome,
              subtitle: _vencimentoSubtitle(items[i]),
              value: formatBrlCurrency(items[i].valor, showDecimals: false),
              numeric: true,
              danger: items[i].status == 'ATRASADO',
              showDivider: i < items.length - 1,
              onTap: () => _openAlunoOrMensalidades(
                context,
                items[i].alunoId,
                source: 'vencimento',
              ),
            ),
        ],
      ),
    );
  }

  String _vencimentoSubtitle(VencimentoItem item) {
    final atrasado = item.status == 'ATRASADO';
    final mes = item.mesReferencia.length >= 7
        ? item.mesReferencia.substring(0, 7)
        : item.mesReferencia;
    return '${atrasado ? 'Atrasado' : 'Vencendo'} · $mes';
  }
}

class _FinanceiroTopAlunosGroup extends StatelessWidget {
  const _FinanceiroTopAlunosGroup({required this.items});

  final List<TopAlunoItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FxSettingsLayout.pageInset),
      child: FxSettingsGroup(
        header: 'Top alunos · acumulado',
        children: [
          for (var i = 0; i < items.length; i++)
            FxSettingsTile(
              fxIcon: 'users',
              label: items[i].alunoNome,
              subtitle: '#${i + 1}',
              value: formatBrlCurrency(items[i].totalPago, showDecimals: false),
              numeric: true,
              showDivider: i < items.length - 1,
              onTap: () => _openAlunoOrMensalidades(
                context,
                items[i].alunoId,
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
