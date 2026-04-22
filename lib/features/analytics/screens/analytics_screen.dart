import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class AnalyticsData {
  final int totalAlunos;
  final int inadimplentes;
  final int wau;
  final int mau;
  final double taxaInadimplencia;
  final double retencaoD7;
  final double retencaoD30;

  AnalyticsData({
    required this.totalAlunos,
    required this.inadimplentes,
    required this.wau,
    required this.mau,
    required this.taxaInadimplencia,
    required this.retencaoD7,
    required this.retencaoD30,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> j) => AnalyticsData(
        totalAlunos: j['totalAlunos'] ?? 0,
        inadimplentes: j['inadimplentes'] ?? 0,
        wau: j['wau'] ?? 0,
        mau: j['mau'] ?? 0,
        taxaInadimplencia: (j['taxaInadimplencia'] ?? 0).toDouble(),
        retencaoD7: (j['retencaoD7'] ?? 0).toDouble(),
        retencaoD30: (j['retencaoD30'] ?? 0).toDouble(),
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

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
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(analyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: Colors.red))),
        data: (data) => _AnalyticsBody(data: data),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsData data;
  const _AnalyticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2B4A9E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Visão Geral', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${data.totalAlunos} alunos ativos',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HeaderBadge(
                      label: '${data.inadimplentes} inadimpl.',
                      color: data.inadimplentes > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 8),
                    _HeaderBadge(
                      label: 'Retenção D7: ${data.retencaoD7.toStringAsFixed(0)}%',
                      color: _retencaoColor(data.retencaoD7),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Métricas WAU / MAU ───────────────────────────────────────
          const _SectionLabel('Engajamento de Alunos'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MetricCard(
                label: 'WAU',
                sublabel: 'Ativos essa semana',
                value: '${data.wau}',
                icon: Icons.people,
                color: const Color(0xFF2B4A9E),
                percent: data.totalAlunos > 0 ? data.wau / data.totalAlunos : 0,
              )),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(
                label: 'MAU',
                sublabel: 'Ativos este mês',
                value: '${data.mau}',
                icon: Icons.calendar_month,
                color: const Color(0xFF22C55E),
                percent: data.totalAlunos > 0 ? data.mau / data.totalAlunos : 0,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // ── Retenção ─────────────────────────────────────────────────
          const _SectionLabel('Taxas de Retenção'),
          const SizedBox(height: 12),
          _RetencaoBar(label: 'Retenção D7 (semanal)', value: data.retencaoD7),
          const SizedBox(height: 8),
          _RetencaoBar(label: 'Retenção D30 (mensal)', value: data.retencaoD30),
          const SizedBox(height: 24),

          // ── Inadimplência ────────────────────────────────────────────
          const _SectionLabel('Inadimplência'),
          const SizedBox(height: 12),
          _RetencaoBar(
            label: 'Taxa de inadimplência',
            value: data.taxaInadimplencia,
            inversed: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _retencaoColor(double v) {
    if (v >= 70) return const Color(0xFF22C55E);
    if (v >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF717171), letterSpacing: 0.5));
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final String value;
  final IconData icon;
  final Color color;
  final double percent;

  const _MetricCard({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.icon,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sublabel, style: const TextStyle(fontSize: 11, color: Color(0xFF717171))),
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
              style: const TextStyle(fontSize: 10, color: Color(0xFF717171))),
        ],
      ),
    );
  }
}

class _RetencaoBar extends StatelessWidget {
  final String label;
  final double value;
  final bool inversed;

  const _RetencaoBar({required this.label, required this.value, this.inversed = false});

  Color get _barColor {
    if (inversed) {
      if (value <= 10) return const Color(0xFF22C55E);
      if (value <= 25) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }
    if (value >= 70) return const Color(0xFF22C55E);
    if (value >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text('${value.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _barColor, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: _barColor.withValues(alpha: 0.1),
            color: _barColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
