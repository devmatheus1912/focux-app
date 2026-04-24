import 'package:fl_chart/fl_chart.dart';
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
  List<Mensalidade> _recentTransactions = [];
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
      final results = await Future.wait([
        repo.dashboard(),
        repo.listar(),
      ]);
      if (mounted) {
        final all = results[1] as List<Mensalidade>;
        // Sort by id descending so newest records appear first, then take up to 8
        final sorted = List<Mensalidade>.from(all)
          ..sort((a, b) => b.id.compareTo(a.id));
        setState(() {
          _data = results[0] as FinanceiroDashboard;
          _recentTransactions = sorted.take(8).toList();
          _loading = false;
        });
      }
    } catch (e) { debugPrint('[Focux] Error: $e');
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryGrid(data: d),
          const SizedBox(height: 20),
          _SectionTitle('Evolução dos últimos 6 meses'),
          const SizedBox(height: 8),
          _BarChart(items: d.evolucaoMensal),
          const SizedBox(height: 20),
          if (d.vencimentosProximos.isNotEmpty) ...[
            _SectionTitle('Vencimentos próximos'),
            const SizedBox(height: 8),
            ...d.vencimentosProximos.map((v) => _VencimentoTile(item: v)),
            const SizedBox(height: 20),
          ],
          if (d.topAlunos.isNotEmpty) ...[
            _SectionTitle('Top alunos por receita'),
            const SizedBox(height: 8),
            ...d.topAlunos.asMap().entries.map((e) => _TopAlunoTile(rank: e.key + 1, item: e.value)),
            const SizedBox(height: 20),
          ],
          if (_recentTransactions.isNotEmpty) ...[
            _SectionTitle('Transações Recentes'),
            const SizedBox(height: 8),
            ..._recentTransactions.map((m) => _TransacaoTile(item: m)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final FinanceiroDashboard data;
  const _SummaryGrid({required this.data});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Expanded(child: _StatCard(
        label: 'Recebido (mês)',
        value: 'R\$ ${data.receitaMes.toStringAsFixed(2)}',
        color: EagleTokens.good,
        icon: Icons.trending_up,
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
        label: 'Previsão (mês)',
        value: 'R\$ ${data.previsaoReceita.toStringAsFixed(2)}',
        color: EagleTokens.brand,
        icon: Icons.schedule,
      )),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _StatCard(
        label: 'Acumulado',
        value: 'R\$ ${data.receitaAcumulada.toStringAsFixed(2)}',
        color: const Color(0xFF7C3AED),
        icon: Icons.account_balance_wallet,
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
        label: 'Ticket médio',
        value: 'R\$ ${data.ticketMedio.toStringAsFixed(2)}',
        color: EagleTokens.brand,
        icon: Icons.receipt_long,
      )),
    ]),
    const SizedBox(height: 12),
    _StatCard(
      label: 'Inadimplentes',
      value: data.totalInadimplentes.toString(),
      color: data.totalInadimplentes > 0 ? EagleTokens.bad : EagleTokens.good,
      icon: Icons.warning_amber_rounded,
      fullWidth: true,
    ),
  ]);
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _StatCard({
    required this.label, required this.value,
    required this.color, required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: EagleTokens.inkMute)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, color: color)),
        ])),
      ]),
    ),
  );
}

class _BarChart extends StatelessWidget {
  final List<EvolucaoMensalItem> items;
  const _BarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final maxY = items.map((e) => e.recebido).reduce((a, b) => a > b ? a : b);
    final chartMax = maxY <= 0 ? 100.0 : maxY * 1.2;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: chartMax,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: chartMax / 4,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: EagleTokens.inkMute.withValues(alpha: 0.2), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                      final mes = items[idx].mes; // "2026-04"
                      final parts = mes.split('-');
                      final label = parts.length >= 2 ? '${parts[1]}/${parts[0].substring(2)}' : mes;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(label, style: const TextStyle(fontSize: 10, color: EagleTokens.inkMute)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: items.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(
                  toY: e.value.recebido,
                  color: colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )],
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _VencimentoTile extends ConsumerStatefulWidget {
  final VencimentoItem item;
  const _VencimentoTile({required this.item});

  @override
  ConsumerState<_VencimentoTile> createState() => _VencimentoTileState();
}

class _VencimentoTileState extends ConsumerState<_VencimentoTile> {
  bool _cobrindo = false;

  Future<void> _cobrar() async {
    setState(() => _cobrindo = true);
    try {
      final msg = await FinanceiroRepository(ref.read(apiClientProvider))
          .cobrarViaChat(widget.item.mensalidadeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _cobrindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAtrasado = widget.item.status == 'ATRASADO';
    final color = isAtrasado ? EagleTokens.bad : EagleTokens.warn;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(isAtrasado ? Icons.warning : Icons.schedule, color: color, size: 20),
        title: Text(widget.item.alunoNome),
        subtitle: Text(widget.item.mesReferencia.substring(0, 7)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('R\$ ${widget.item.valor.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(widget.item.status, style: TextStyle(fontSize: 10, color: color)),
              ],
            ),
            const SizedBox(width: 12),
            if (isAtrasado)
              IconButton(
                onPressed: _cobrindo ? null : _cobrar,
                icon: _cobrindo
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.notifications_active, color: EagleTokens.brand, size: 20),
                tooltip: 'Cobrar no chat',
              ),
          ],
        ),
      ),
    );
  }
}

class _TopAlunoTile extends StatelessWidget {
  final int rank;
  final TopAlunoItem item;
  const _TopAlunoTile({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        child: Text('$rank', style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary)),
      ),
      title: Text(item.alunoNome),
      trailing: Text('R\$ ${item.totalPago.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}

class _TransacaoTile extends StatelessWidget {
  final Mensalidade item;
  const _TransacaoTile({required this.item});

  IconData _icon(String status) {
    switch (status) {
      case 'PAGO': return Icons.check_circle;
      case 'ATRASADO': return Icons.cancel;
      default: return Icons.schedule;
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'PAGO': return EagleTokens.good;
      case 'ATRASADO': return EagleTokens.bad;
      default: return EagleTokens.warn;
    }
  }

  String _dateLabel(Mensalidade m) {
    if (m.status == 'PAGO' && m.pagoEm != null && m.pagoEm!.isNotEmpty) {
      try {
        final dt = DateTime.parse(m.pagoEm!);
        final d = dt.day.toString().padLeft(2, '0');
        final mo = dt.month.toString().padLeft(2, '0');
        return 'Pago em $d/$mo/${dt.year}';
      } catch (_) {}
    }
    final parts = m.mesReferencia.split('-');
    if (parts.length >= 2) return 'Ref. ${parts[1]}/${parts[0]}';
    return m.mesReferencia;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final statusColor = _color(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(_icon(item.status), color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.alunoNome,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel(item),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${item.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
