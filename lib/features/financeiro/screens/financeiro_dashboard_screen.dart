import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';

class FinanceiroDashboardScreen extends ConsumerStatefulWidget {
  const FinanceiroDashboardScreen({super.key});

  @override
  ConsumerState<FinanceiroDashboardScreen> createState() => _FinanceiroDashboardScreenState();
}

class _FinanceiroDashboardScreenState extends ConsumerState<FinanceiroDashboardScreen> {
  FinanceiroDashboard? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = FinanceiroRepository(ref.read(apiClientProvider));
      final dashboard = await repo.dashboard();
      if (mounted) {
        setState(() {
          _data = dashboard;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Erro ao carregar dashboard.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
        ]),
      );
    }

    final d = _data!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          const SizedBox(height: 16),
          // Hero — ring with received amount
          _HeroRing(data: d, isDark: isDark),
          
          // Tri-grid metrics
          _TriGrid(data: d, isDark: isDark),
          
          // Evolução — bar chart
          _EvolucaoChart(items: d.evolucaoMensal, isDark: isDark),
          
          // Vencimentos próximos
          if (d.vencimentosProximos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vencimentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.darkInk : EagleTokens.ink, letterSpacing: -0.2)),
                  Text('Cobrar todos →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.brandAccent : EagleTokens.brand)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: d.vencimentosProximos.map((v) => _VencimentoRow(item: v, isDark: isDark)).toList(),
              ),
            ),
          ],
          
          // Top alunos
          if (d.topAlunos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Text('Top alunos · acumulado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.darkInk : EagleTokens.ink, letterSpacing: -0.2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? null : Border.all(color: EagleTokens.line),
                ),
                child: Column(
                  children: d.topAlunos.asMap().entries.map((e) {
                    final rank = e.key + 1;
                    final t = e.value;
                    final isLast = rank == d.topAlunos.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: isLast ? null : Border(bottom: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.15) : EagleTokens.brandSoft,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? EagleTokens.brandAccent : EagleTokens.brand)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: isDark ? EagleTokens.brandDeep : EagleTokens.brand, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(t.alunoNome.isNotEmpty ? t.alunoNome[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.alunoNome, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: isDark ? EagleTokens.darkInk : EagleTokens.ink), overflow: TextOverflow.ellipsis)),
                          Text('R\$ ${(t.totalPago / 1000).toStringAsFixed(1)}k', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.darkInk : EagleTokens.ink)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _HeroRing extends StatelessWidget {
  final FinanceiroDashboard data;
  final bool isDark;
  
  const _HeroRing({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    
    final perc = data.previsaoReceita > 0 ? (data.receitaMes / data.previsaoReceita) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: isDark ? null : Border.all(color: line),
        ),
        child: Row(
          children: [
            // Ring
            SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : EagleTokens.brandSoft,
                    ),
                  ),
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      value: perc.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: isDark ? EagleTokens.brandAccent : EagleTokens.brand,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('RECEBIDO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: ink)),
                      Text('${(perc * 100).round()}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: ink)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RECEBIDO NESTE MÊS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: mute)),
                  const SizedBox(height: 3),
                  Text('R\$ ${data.receitaMes.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: ink, height: 1.1)),
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'Previsto ', style: TextStyle(fontSize: 12.5, color: mute)),
                    TextSpan(text: 'R\$ ${data.previsaoReceita.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(fontSize: 12.5, color: ink, fontWeight: FontWeight.w600)),
                  ])),
                  const SizedBox(height: 10),
                  if (data.totalInadimplentes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x1FFF8B8B) : EagleTokens.badSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad),
                          const SizedBox(width: 6),
                          Text('${data.totalInadimplentes} inadimpl.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)),
                        ],
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

class _TriGrid extends StatelessWidget {
  final FinanceiroDashboard data;
  final bool isDark;
  const _TriGrid({required this.data, required this.isDark});

  String _formatK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // Pendente = Previsão - Recebido (approx)
    final pendente = math.max(0.0, data.previsaoReceita - data.receitaMes);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Row(
        children: [
          Expanded(child: _MiniMetric(label: 'Pendente', value: 'R\$ ${_formatK(pendente)}', isDark: isDark)),
          const SizedBox(width: 8),
          Expanded(child: _MiniMetric(label: 'Ticket', value: 'R\$ ${data.ticketMedio.toStringAsFixed(0)}', isDark: isDark)),
          const SizedBox(width: 8),
          Expanded(child: _MiniMetric(label: 'Acumul.', value: 'R\$ ${_formatK(data.receitaAcumulada)}', isDark: isDark)),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _MiniMetric({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? null : Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: mute,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: ink)),
        ],
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
    
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    
    final maxV = items.map((e) => e.recebido).reduce(math.max);
    final chartMax = maxV <= 0 ? 100.0 : maxV;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: isDark ? null : Border.all(color: line),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Evolução · 6 meses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: ink)),
                if (items.length > 1)
                  Builder(builder: (_) {
                    final prev = items[items.length - 2].recebido;
                    final curr = items.last.recebido;
                    if (prev > 0) {
                      final diff = ((curr - prev) / prev * 100).round();
                      final sign = diff > 0 ? '+' : '';
                      return Text('$sign$diff% vs ${items[items.length - 2].mes.substring(5)}', style: TextStyle(fontSize: 11, color: mute));
                    }
                    return const SizedBox.shrink();
                  }),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items.asMap().entries.map((e) {
                  final isLast = e.key == items.length - 1;
                  final h = (e.value.recebido / chartMax).clamp(0.05, 1.0);
                  
                  final mes = e.value.mes;
                  final label = mes.length >= 7 ? mes.substring(5) : mes; // get just month number or string
                  
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(e.value.recebido / 1000).toStringAsFixed(1)}k', style: TextStyle(fontSize: 9.5, color: isLast ? ink : mute, fontWeight: isLast ? FontWeight.w600 : FontWeight.w400)),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: h,
                              widthFactor: 0.7,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
                                  gradient: isLast
                                      ? LinearGradient(
                                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                          colors: isDark ? [EagleTokens.brandAccent, EagleTokens.brand] : [EagleTokens.brand, EagleTokens.brandDeep],
                                        )
                                      : null,
                                  color: !isLast ? (isDark ? Colors.white.withValues(alpha: 0.08) : EagleTokens.brandSoft) : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(label, style: TextStyle(fontSize: 10, color: isLast ? ink : mute, fontWeight: isLast ? FontWeight.w600 : FontWeight.w500, letterSpacing: 0.4)),
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

class _VencimentoRow extends StatelessWidget {
  final VencimentoItem item;
  final bool isDark;
  const _VencimentoRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    
    final isAtrasado = item.status == 'ATRASADO';
    final color = isAtrasado ? (isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad) : (isDark ? const Color(0xFFE2B46F) : EagleTokens.warn);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: line),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: isDark ? EagleTokens.brandDeep : EagleTokens.brand, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(item.alunoNome.isNotEmpty ? item.alunoNome[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.alunoNome, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: ink)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(isAtrasado ? 'Atrasado' : 'Vencendo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
                    Text(' · ${item.mesReferencia.substring(0, 7)}', style: TextStyle(fontSize: 11.5, color: mute)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('R\$ ${item.valor.toStringAsFixed(0)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.2)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : EagleTokens.brandSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Cobrar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.brandAccent : EagleTokens.brand)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
