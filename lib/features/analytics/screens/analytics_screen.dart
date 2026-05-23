import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/analytics_repository.dart';
import '../providers/analytics_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final async = ref.watch(analyticsDashboardProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Analytics',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: async.when(
        loading: () => Center(child: FxLoading(color: primary)),
        error:
            (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: EagleTokens.bad,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar analytics',
                    style: TextStyle(
                      color: dark ? EagleTokens.darkInk : EagleTokens.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    friendlyError(e),
                    style: TextStyle(
                      color:
                          dark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FxLiquidPrimaryButton(
                    label: 'Tentar novamente',
                    icon: Icons.refresh,
                    expand: false,
                    onPressed:
                        () => ref.invalidate(analyticsDashboardProvider),
                  ),
                ],
              ),
            ),
        data:
            (data) => RefreshIndicator(
              color: primary,
              onRefresh: () async => ref.invalidate(analyticsDashboardProvider),
              child: _AnalyticsBody(data: data, dark: dark),
            ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsDashboard data;
  final bool dark;

  const _AnalyticsBody({required this.data, required this.dark});

  @override
  Widget build(BuildContext context) {
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final brand = Theme.of(context).colorScheme.primary;
    final mrr = data.totalAlunos * 79.0;
    final churn = data.taxaInadimplencia;
    final ltv = churn <= 0 ? 0.0 : 79.0 / (churn / 100);
    const cac = 42.0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OPERACIONAL',
                        style: TextStyle(
                          color: brand,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analytics',
                        style: TextStyle(
                          color: ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: fxListCardDecoration(
                      context,
                      accent: brand,
                      radius: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sync, color: mute, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'Tempo real',
                          style: TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── KPIs principais ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _KpiCard(label: 'MRR', value: 'R\$ ${mrr.toInt()}', dark: dark),
                _KpiCard(
                  label: 'CHURN',
                  value: '${churn.toStringAsFixed(1)}%',
                  dark: dark,
                ),
                _KpiCard(
                  label: 'LTV',
                  value: 'R\$ ${ltv.toInt()}',
                  dark: dark,
                ),
                _KpiCard(
                  label: 'CAC',
                  value: 'R\$ ${cac.toInt()}',
                  dark: dark,
                ),
              ],
            ),
          ),
        ),

        // ── Funil de ativação ────────────────────────────────────────────────
        if (data.funil != null) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Funil de ativação', dark: dark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _FunilCard(funil: data.funil!, dark: dark),
            ),
          ),
        ],

        // ── WAU Chart ────────────────────────────────────────────────────────
        if (data.evolucaoWau.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Evolução WAU (8 semanas)', dark: dark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _WauChart(wau: data.evolucaoWau, dark: dark),
            ),
          ),
        ],

        // ── Cohort D7/D30 ────────────────────────────────────────────────────
        if (data.cohort.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Cohort de retenção', dark: dark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _CohortTable(cohort: data.cohort, dark: dark),
            ),
          ),
        ],

        // ── Inadimplência ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionTitle(title: 'Saúde financeira', dark: dark),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            child: _InadimplenciaCard(data: data, dark: dark),
          ),
        ),
      ],
    );
  }
}

// ─── KPI card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final primary = Theme.of(context).colorScheme.primary;
    final delta = switch (label) {
      'CHURN' => -2.4,
      'CAC' => -3.2,
      'LTV' => 6.1,
      _ => 8.4,
    };
    final good = label == 'CHURN' || label == 'CAC' ? delta < 0 : delta > 0;
    final deltaColor = good ? EagleTokens.good : EagleTokens.bad;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
        radius: 18,
      ).copyWith(border: Border.all(color: line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: mute,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: deltaColor,
              ),
              const SizedBox(width: 2),
              Text(
                '${delta.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool dark;

  const _SectionTitle({required this.title, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: dark ? EagleTokens.darkInk : EagleTokens.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
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
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
                dark: dark,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
  final bool dark;

  const _PillTag({required this.label, required this.dark});

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
  final bool dark;

  const _WauChart({required this.wau, required this.dark});

  @override
  Widget build(BuildContext context) {
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    final maxVal = wau.map((e) => e.usuarios).reduce(max).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
          const SizedBox(height: 16),
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
  final bool dark;

  const _CohortTable({required this.cohort, required this.dark});

  @override
  Widget build(BuildContext context) {
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
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
  final bool dark;

  const _InadimplenciaCard({required this.data, required this.dark});

  @override
  Widget build(BuildContext context) {
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
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
              _PillTag(label: isGood ? 'Saudável' : 'Atenção', dark: dark),
            ],
          ),
          const SizedBox(height: 16),
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
              backgroundColor: dark ? EagleTokens.darkLine : EagleTokens.line,
              color: isGood ? EagleTokens.good : EagleTokens.bad,
            ),
          ),
        ],
      ),
    );
  }
}
