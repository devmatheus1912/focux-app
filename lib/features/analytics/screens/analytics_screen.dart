import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class FunilAtivacao {
  final int cadastrados, fizeram1Checkin, fizeram3Checkins, ativos30Dias;
  final double taxaAtivacao, taxaEngajamento, taxaRetencao;
  FunilAtivacao.fromJson(Map<String, dynamic> j)
      : cadastrados       = j['cadastrados'] ?? 0,
        fizeram1Checkin   = j['fizeram1Checkin'] ?? 0,
        fizeram3Checkins  = j['fizeram3Checkins'] ?? 0,
        ativos30Dias      = j['ativos30Dias'] ?? 0,
        taxaAtivacao      = (j['taxaAtivacao'] ?? 0).toDouble(),
        taxaEngajamento   = (j['taxaEngajamento'] ?? 0).toDouble(),
        taxaRetencao      = (j['taxaRetencao'] ?? 0).toDouble();
}

class WauSemanal {
  final String semana;
  final int usuarios;
  WauSemanal.fromJson(Map<String, dynamic> j)
      : semana   = j['semana'] ?? '',
        usuarios = j['usuarios'] ?? 0;
}

class CohortRetencao {
  final String mesEntrada;
  final int cadastrados, ativosD7, ativosD30;
  final double retencaoD7, retencaoD30;
  CohortRetencao.fromJson(Map<String, dynamic> j)
      : mesEntrada   = j['mesEntrada'] ?? '',
        cadastrados  = j['cadastrados'] ?? 0,
        ativosD7     = j['ativosD7'] ?? 0,
        ativosD30    = j['ativosD30'] ?? 0,
        retencaoD7   = (j['retencaoD7'] ?? 0).toDouble(),
        retencaoD30  = (j['retencaoD30'] ?? 0).toDouble();
}

class AnalyticsData {
  final int totalAlunos, inadimplentes, wau, mau;
  final double taxaInadimplencia, retencaoD7, retencaoD30;
  final FunilAtivacao? funil;
  final List<WauSemanal> evolucaoWau;
  final List<CohortRetencao> cohort;

  AnalyticsData.fromJson(Map<String, dynamic> j)
      : totalAlunos        = j['totalAlunos'] ?? 0,
        inadimplentes      = j['inadimplentes'] ?? 0,
        wau                = j['wau'] ?? 0,
        mau                = j['mau'] ?? 0,
        taxaInadimplencia  = (j['taxaInadimplencia'] ?? 0).toDouble(),
        retencaoD7         = (j['retencaoD7'] ?? 0).toDouble(),
        retencaoD30        = (j['retencaoD30'] ?? 0).toDouble(),
        funil = j['funil'] != null ? FunilAtivacao.fromJson(j['funil']) : null,
        evolucaoWau = (j['evolucaoWau'] as List? ?? [])
            .map((e) => WauSemanal.fromJson(e as Map<String, dynamic>))
            .toList(),
        cohort = (j['cohort'] as List? ?? [])
            .map((e) => CohortRetencao.fromJson(e as Map<String, dynamic>))
            .toList();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/analytics');
  return AnalyticsData.fromJson(res.data as Map<String, dynamic>);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Avançado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(analyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e', style: const TextStyle(color: EagleTokens.bad)),
        ),
        data: (data) => _AnalyticsBody(data: data),
      ),
    );
  }
}

// ─── Body com tabs ────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsData data;
  const _AnalyticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _HeroHeader(data: data),
          const TabBar(
            tabs: [
              Tab(text: 'Visão Geral'),
              Tab(text: 'Funil'),
              Tab(text: 'Cohort'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TabVisaoGeral(data: data),
                _TabFunil(funil: data.funil, evolucao: data.evolucaoWau),
                _TabCohort(cohort: data.cohort),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final AnalyticsData data;
  const _HeroHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EagleTokens.heroGradient(dark: isDark),
        borderRadius: BorderRadius.circular(EagleTokens.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total de Alunos', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('${data.totalAlunos}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  _Badge('D7: ${data.retencaoD7.toStringAsFixed(0)}%', _retColor(data.retencaoD7)),
                  const SizedBox(width: 8),
                  _Badge('D30: ${data.retencaoD30.toStringAsFixed(0)}%', _retColor(data.retencaoD30)),
                ]),
              ],
            ),
          ),
          Column(children: [
            _StatPill('WAU', data.wau),
            const SizedBox(height: 8),
            _StatPill('MAU', data.mau),
          ]),
        ],
      ),
    );
  }

  Color _retColor(double v) {
    if (v >= 70) return EagleTokens.good;
    if (v >= 40) return EagleTokens.warn;
    return EagleTokens.bad;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(EagleTokens.radiusChip),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  const _StatPill(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(EagleTokens.radiusSmall),
        ),
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      );
}

// ─── Tab 1: Visão Geral ───────────────────────────────────────────────────────

class _TabVisaoGeral extends StatelessWidget {
  final AnalyticsData data;
  const _TabVisaoGeral({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Engajamento'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard('WAU', '${data.wau}', 'ativos essa semana',
                Icons.people, EagleTokens.brand,
                data.totalAlunos > 0 ? data.wau / data.totalAlunos : 0)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard('MAU', '${data.mau}', 'ativos este mês',
                Icons.calendar_month, EagleTokens.good,
                data.totalAlunos > 0 ? data.mau / data.totalAlunos : 0)),
          ]),
          const SizedBox(height: 24),
          const _SectionLabel('Taxas de Retenção'),
          const SizedBox(height: 12),
          _RetencaoBar('Retenção D7 (semanal)', data.retencaoD7),
          const SizedBox(height: 8),
          _RetencaoBar('Retenção D30 (mensal)', data.retencaoD30),
          const SizedBox(height: 24),
          const _SectionLabel('Inadimplência'),
          const SizedBox(height: 12),
          _RetencaoBar('Taxa de inadimplência', data.taxaInadimplencia, inversed: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard('Inadimplentes', '${data.inadimplentes}', 'alunos em atraso',
                Icons.warning_amber_rounded, EagleTokens.bad,
                data.totalAlunos > 0 ? data.inadimplentes / data.totalAlunos : 0)),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Tab 2: Funil de Ativação ─────────────────────────────────────────────────

class _TabFunil extends StatelessWidget {
  final FunilAtivacao? funil;
  final List<WauSemanal> evolucao;
  const _TabFunil({required this.funil, required this.evolucao});

  @override
  Widget build(BuildContext context) {
    if (funil == null) {
      return const Center(child: Text('Sem dados de funil disponíveis'));
    }
    final f = funil!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Funil de Ativação (90 dias)'),
          const SizedBox(height: 16),
          _FunilStep('Cadastrados', f.cadastrados, f.cadastrados, EagleTokens.brand, isFirst: true),
          _FunilArrow(label: '${f.taxaAtivacao.toStringAsFixed(0)}% ativação'),
          _FunilStep('1° Check-in', f.fizeram1Checkin, f.cadastrados, EagleTokens.brand),
          _FunilArrow(label: '${f.taxaEngajamento.toStringAsFixed(0)}% engajamento'),
          _FunilStep('3+ Check-ins', f.fizeram3Checkins, f.cadastrados, EagleTokens.warn),
          _FunilArrow(label: '${f.taxaRetencao.toStringAsFixed(0)}% retenção'),
          _FunilStep('Ativos 30d', f.ativos30Dias, f.cadastrados, EagleTokens.good),
          const SizedBox(height: 24),
          if (evolucao.isNotEmpty) ...[
            const _SectionLabel('Evolução WAU (últimas 8 semanas)'),
            const SizedBox(height: 12),
            ...evolucao.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WauBar(semana: s.semana, usuarios: s.usuarios,
                  max: evolucao.map((e) => e.usuarios).reduce((a, b) => a > b ? a : b)),
            )),
          ],
        ],
      ),
    );
  }
}

class _FunilStep extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  final bool isFirst;
  const _FunilStep(this.label, this.count, this.total, this.color, {this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(EagleTokens.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
        ]),
      ]),
    );
  }
}

class _FunilArrow extends StatelessWidget {
  final String label;
  const _FunilArrow({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
    child: Row(children: [
      const Icon(Icons.arrow_downward, size: 16, color: EagleTokens.inkMute),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute)),
    ]),
  );
}

class _WauBar extends StatelessWidget {
  final String semana;
  final int usuarios, max;
  const _WauBar({required this.semana, required this.usuarios, required this.max});
  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? usuarios / max : 0.0;
    return Row(children: [
      SizedBox(width: 80, child: Text(semana.replaceFirst('W', ' W'),
          style: const TextStyle(fontSize: 11, color: EagleTokens.inkMute))),
      Expanded(child: LinearProgressIndicator(
        value: pct.clamp(0.0, 1.0),
        backgroundColor: EagleTokens.brand.withValues(alpha: 0.1),
        color: EagleTokens.brand,
        minHeight: 12,
        borderRadius: BorderRadius.circular(4),
      )),
      const SizedBox(width: 8),
      Text('$usuarios', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ─── Tab 3: Cohort D7/D30 ────────────────────────────────────────────────────

class _TabCohort extends StatelessWidget {
  final List<CohortRetencao> cohort;
  const _TabCohort({required this.cohort});

  @override
  Widget build(BuildContext context) {
    if (cohort.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.grid_view, size: 48, color: EagleTokens.inkMute),
          SizedBox(height: 12),
          Text('Sem dados de cohort ainda.\nCadastre alunos e realize check-ins.',
              textAlign: TextAlign.center),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Cohort de Retenção por Mês de Cadastro'),
          const SizedBox(height: 4),
          const Text('D7 = alunos que fizeram check-in nos primeiros 7 dias.',
              style: TextStyle(fontSize: 11, color: EagleTokens.inkMute)),
          const SizedBox(height: 16),
          // Tabela de cohort
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.2),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: EagleTokens.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Mês', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Cadastr.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Ret. D7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Ret. D30', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              // Dados
              ...cohort.map((c) => TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: EagleTokens.outlineLight.withValues(alpha: 0.5))),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(c.mesEntrada, style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${c.cadastrados}', style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${c.retencaoD7.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _retColor(c.retencaoD7),
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${c.retencaoD30.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _retColor(c.retencaoD30),
                        )),
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 24),
          // Mini heatmap visual por cohort
          const _SectionLabel('Heatmap de Retenção D30'),
          const SizedBox(height: 12),
          ...cohort.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 70, child: Text(c.mesEntrada,
                  style: const TextStyle(fontSize: 11, color: EagleTokens.inkMute))),
              Expanded(child: LinearProgressIndicator(
                value: (c.retencaoD30 / 100).clamp(0.0, 1.0),
                backgroundColor: EagleTokens.brand.withValues(alpha: 0.08),
                color: _retColor(c.retencaoD30),
                minHeight: 14,
                borderRadius: BorderRadius.circular(4),
              )),
              const SizedBox(width: 8),
              Text('${c.retencaoD30.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _retColor(c.retencaoD30),
                  )),
            ]),
          )),
        ],
      ),
    );
  }

  Color _retColor(double v) {
    if (v >= 70) return EagleTokens.good;
    if (v >= 40) return EagleTokens.warn;
    return EagleTokens.bad;
  }
}

// ─── Widgets compartilhados ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold,
        color: EagleTokens.inkMute, letterSpacing: 0.5));
}

class _MetricCard extends StatelessWidget {
  final String label, value, sublabel;
  final IconData icon;
  final Color color;
  final double percent;
  const _MetricCard(this.label, this.value, this.sublabel, this.icon, this.color, this.percent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(EagleTokens.radiusCard),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(sublabel, style: const TextStyle(fontSize: 11, color: EagleTokens.inkMute)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text('${(percent * 100).toStringAsFixed(0)}% do total',
              style: const TextStyle(fontSize: 10, color: EagleTokens.inkMute)),
        ],
      ),
    );
  }
}

class _RetencaoBar extends StatelessWidget {
  final String label;
  final double value;
  final bool inversed;
  const _RetencaoBar(this.label, this.value, {this.inversed = false});

  Color get _barColor {
    if (inversed) {
      if (value <= 10) return EagleTokens.good;
      if (value <= 25) return EagleTokens.warn;
      return EagleTokens.bad;
    }
    if (value >= 70) return EagleTokens.good;
    if (value >= 40) return EagleTokens.warn;
    return EagleTokens.bad;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(EagleTokens.radiusSmall),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text('${value.toStringAsFixed(1)}%',
              style: TextStyle(fontWeight: FontWeight.bold, color: _barColor, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (value / 100).clamp(0.0, 1.0),
          backgroundColor: _barColor.withValues(alpha: 0.1),
          color: _barColor,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ]),
    );
  }
}
