part of 'financeiro_dashboard_screen.dart';

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
                Text(
                  'Evolução · 6 meses',
                  style: FocuxHubTypography.body(
                    color: ink,
                  ).copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
                ),
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
                              '${(e.value.recebido.cents / 100000).toStringAsFixed(1)}k',
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
                item.valor.format(showDecimals: false),
                style: FocuxHubTypography.bodyMuted(
                  color:
                      item.status == 'ATRASADO'
                          ? EagleTokens.bad
                          : fxScreenMute(context),
                  fontWeight: FontWeight.w700,
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
                visible[i].totalPago.format(showDecimals: false),
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
