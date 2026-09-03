part of 'analytics_screen.dart';

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsDashboard data;
  final bool dark;

  const _AnalyticsBody({required this.data, required this.dark});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final brand = Theme.of(context).colorScheme.primary;
    final churn = data.taxaInadimplencia;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              TokensStrip.s2,
              TokensStrip.s4,
              TokensStrip.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label:
                      'Inadimplência ${churn.toStringAsFixed(1)} por cento',
                  child: FxStripCard(
                  emphasize: true,
                  semanticsLabel:
                      'Inadimplência ${churn.toStringAsFixed(1)} por cento',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inadimplência',
                        style: FocuxHubTypography.chip(mute),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${churn.toStringAsFixed(1)}%',
                        style: FocuxHubTypography.kpi(
                          color: ink,
                          fontSize: FocuxHubTypography.metricLg,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.inadimplentes == 0
                            ? 'Nenhuma cobrança em atraso'
                            : '${data.inadimplentes} ${data.inadimplentes == 1 ? 'aluno' : 'alunos'} em atraso',
                        style: FocuxHubTypography.body(
                          color: ink,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: TokensStrip.s3),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DashboardHomeActionChip(
                          label: 'Ver financeiro',
                          accent:
                              data.inadimplentes > 0
                                  ? EagleTokens.bad
                                  : brand,
                          isDark: dark,
                          onPressed: () => context.push('/financeiro'),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: TokensStrip.s3),
                OperationalMetricTile(
                  label: 'WAU',
                  value: '${data.wau}',
                  hint: 'MAU ${data.mau}',
                  color: brand,
                  isDark: dark,
                ),
                const SizedBox(height: TokensStrip.s2),
                OperationalMetricTile(
                  label: 'Retenção D30',
                  value: '${data.retencaoD30.toStringAsFixed(1)}%',
                  hint: 'D7 ${data.retencaoD7.toStringAsFixed(1)}%',
                  color: EagleTokens.good,
                  isDark: dark,
                ),
              ],
            ),
          ),
        ),

        // ── Funil de ativação ────────────────────────────────────────────────
        if (data.funil != null) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Funil de ativação'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 14),
              child: _FunilCard(funil: data.funil!, dark: dark),
            ),
          ),
        ],

        // ── WAU Chart ────────────────────────────────────────────────────────
        if (data.evolucaoWau.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Evolução WAU (8 semanas)'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 14),
              child: _WauChart(wau: data.evolucaoWau),
            ),
          ),
        ],

        // ── Cohort D7/D30 ────────────────────────────────────────────────────
        if (data.cohort.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Cohort de retenção'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 14),
              child: _CohortTable(cohort: data.cohort),
            ),
          ),
        ],

        // ── Inadimplência ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionTitle(title: 'Saúde financeira'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 110),
            child: _InadimplenciaCard(data: data),
          ),
        ),
      ],
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 4, 20, 10),
      child: Text(
        title,
        style: FocuxHubTypography.sectionTitle(
          context,
          color: ShellChrome.of(context).ink,
        ),
      ),
    );
  }
}

// ─── Funil card ───────────────────────────────────────────────────────────────

class _FunilCard extends StatelessWidget {
  final FunilAtivacao funil;
  final bool dark;

  const _FunilCard({required this.funil, required this.dark});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final primary = Theme.of(context).colorScheme.primary;

    final steps = [
      _FunilStep('Cadastrados', funil.cadastrados, 1.0),
      _FunilStep(
        '1 check-in',
        funil.fizeram1Checkin,
        funil.cadastrados > 0 ? funil.fizeram1Checkin / funil.cadastrados : 0,
      ),
      _FunilStep(
        '3 check-ins',
        funil.fizeram3Checkins,
        funil.cadastrados > 0 ? funil.fizeram3Checkins / funil.cadastrados : 0,
      ),
      _FunilStep(
        'Ativos 30d',
        funil.ativos30Dias,
        funil.cadastrados > 0 ? funil.ativos30Dias / funil.cadastrados : 0,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 18, 16, 18),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
        radius: 22,
      ).copyWith(border: Border.all(color: line)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ativação: ${(funil.taxaAtivacao * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _PillTag(
                label:
                    'Engaj: ${(funil.taxaEngajamento * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          ...steps.map(
            (s) => _FunilBar(step: s, ink: ink, mute: mute, dark: dark),
          ),
        ],
      ),
    );
  }
}

class _FunilStep {
  final String label;
  final int value;
  final double ratio;
  const _FunilStep(this.label, this.value, this.ratio);
}

class _FunilBar extends StatelessWidget {
  final _FunilStep step;
  final Color ink;
  final Color mute;
  final bool dark;

  const _FunilBar({
    required this.step,
    required this.ink,
    required this.mute,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: dark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(step.label, style: TextStyle(color: mute, fontSize: 12)),
              Text(
                '${step.value} · ${(step.ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step.ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: dark ? EagleTokens.darkLine : primarySoft,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;

  const _PillTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── WAU chart ────────────────────────────────────────────────────────────────

class _WauChart extends StatelessWidget {
  final List<WauSemanal> wau;

  const _WauChart({required this.wau});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    final maxVal = wau.map((e) => e.usuarios).reduce(max).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 18, 16, 18),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
        radius: 22,
      ).copyWith(border: Border.all(color: line)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usuários ativos / semana',
                style: TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'pico: ${wau.map((e) => e.usuarios).reduce(max)}',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  wau.asMap().entries.map((entry) {
                    final isLast = entry.key == wau.length - 1;
                    final h = maxVal > 0 ? entry.value.usuarios / maxVal : 0.0;
                    final semana =
                        entry.value.semana.length >= 5
                            ? entry.value.semana.substring(5) // MM-DD
                            : entry.value.semana;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isLast)
                              Text(
                                '${entry.value.usuarios}',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            const SizedBox(height: 3),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: h.clamp(0.05, 1.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isLast
                                              ? LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [primary, primaryDeep],
                                              )
                                              : null,
                                      color:
                                          isLast
                                              ? null
                                              : primary.withValues(alpha: 0.22),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                        bottom: Radius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              semana,
                              style: TextStyle(
                                color: isLast ? ink : mute,
                                fontSize: 9,
                                fontWeight:
                                    isLast ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cohort table ─────────────────────────────────────────────────────────────

class _CohortTable extends StatelessWidget {
  final List<CohortRetencao> cohort;

  const _CohortTable({required this.cohort});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 18, 16, 12),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
        radius: 22,
      ).copyWith(border: Border.all(color: line)),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Mês',
                  style: TextStyle(
                    color: mute,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Cad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'D7',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'D30',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EagleTokens.good,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: line, height: 20),
          ...cohort.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      c.mesEntrada,
                      style: TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${c.cadastrados}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mute, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: _RetencaoBadge(value: c.retencaoD7, color: primary),
                  ),
                  Expanded(
                    child: _RetencaoBadge(
                      value: c.retencaoD30,
                      color: EagleTokens.good,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetencaoBadge extends StatelessWidget {
  final double value;
  final Color color;

  const _RetencaoBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${value.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Inadimplência card ───────────────────────────────────────────────────────

class _InadimplenciaCard extends StatelessWidget {
  final AnalyticsDashboard data;

  const _InadimplenciaCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final churn = data.taxaInadimplencia;
    final isGood = churn < 5.0;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
        radius: 22,
      ).copyWith(border: Border.all(color: line)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taxa de inadimplência',
                style: TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _PillTag(label: isGood ? 'Saudável' : 'Atenção'),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${churn.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isGood ? EagleTokens.good : EagleTokens.bad,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.inadimplentes} de ${data.totalAlunos} alunos',
                      style: TextStyle(color: mute, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: FxLoading(
                  value: (churn / 100).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: (isGood ? EagleTokens.good : EagleTokens.bad)
                      .withValues(alpha: 0.15),
                  color: isGood ? EagleTokens.good : EagleTokens.bad,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Meta line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meta', style: TextStyle(color: mute, fontSize: 11)),
              Text(
                '< 5%',
                style: TextStyle(
                  color: EagleTokens.good,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (churn / 10).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  ShellChrome.of(context).line,
              color: isGood ? EagleTokens.good : EagleTokens.bad,
            ),
          ),
        ],
      ),
    );
  }
}
