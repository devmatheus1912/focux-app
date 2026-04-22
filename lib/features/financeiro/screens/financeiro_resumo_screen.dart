import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';

class FinanceiroResumoScreen extends ConsumerStatefulWidget {
  const FinanceiroResumoScreen({super.key});

  @override
  ConsumerState<FinanceiroResumoScreen> createState() => _FinanceiroResumoScreenState();
}

class _FinanceiroResumoScreenState extends ConsumerState<FinanceiroResumoScreen> {
  late int _ano;
  late int _mes;
  bool _loading = false;
  ResumoMensal? _resumo;
  String? _erro;

  static const _meses = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final r = await FinanceiroRepository(ref.read(apiClientProvider))
          .resumoMensal(_ano, _mes);
      if (mounted) setState(() { _resumo = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  void _mesAnterior() {
    setState(() {
      if (_mes == 1) { _mes = 12; _ano--; }
      else { _mes--; }
    });
    _carregar();
  }

  void _mesProximo() {
    setState(() {
      if (_mes == 12) { _mes = 1; _ano++; }
      else { _mes++; }
    });
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          // Month/year picker
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _mesAnterior,
                  tooltip: 'Mês anterior',
                ),
                const SizedBox(width: 8),
                Text(
                  '${_meses[_mes]} $_ano',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _mesProximo,
                  tooltip: 'Próximo mês',
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: EagleTokens.danger),
                            const SizedBox(height: 8),
                            Text('Erro ao carregar resumo', style: TextStyle(color: cs.error)),
                            const SizedBox(height: 4),
                            Text(_erro!, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _carregar,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _resumo == null
                        ? const Center(child: Text('Sem dados para exibir.'))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _DonutChartCard(resumo: _resumo!),
                              const SizedBox(height: 16),
                              _ResumoCard(
                                titulo: 'Total recebido',
                                valor: 'R\$ ${_resumo!.totalRecebido.toStringAsFixed(2)}',
                                icone: Icons.check_circle,
                                cor: EagleTokens.success,
                              ),
                              _ResumoCard(
                                titulo: 'Total previsto',
                                valor: 'R\$ ${_resumo!.totalPrevisto.toStringAsFixed(2)}',
                                icone: Icons.trending_up,
                                cor: EagleTokens.primary,
                              ),
                              _ResumoCard(
                                titulo: 'Inadimplentes',
                                valor: '${_resumo!.inadimplentes}',
                                icone: Icons.warning_amber,
                                cor: EagleTokens.danger,
                              ),
                              _ResumoCard(
                                titulo: 'Ticket médio',
                                valor: 'R\$ ${_resumo!.ticketMedio.toStringAsFixed(2)}',
                                icone: Icons.receipt_long,
                                cor: cs.primary,
                              ),
                              _ResumoCard(
                                titulo: 'Acumulado anual',
                                valor: 'R\$ ${_resumo!.acumuladoAnual.toStringAsFixed(2)}',
                                icone: Icons.savings,
                                cor: const Color(0xFF7C3AED),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartCard extends StatelessWidget {
  final ResumoMensal resumo;
  const _DonutChartCard({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final double recebido = resumo.totalRecebido;
    final double previsto = resumo.totalPrevisto;
    final double pendente = previsto > recebido ? (previsto - recebido) : 0;
    
    final bool isEmpty = previsto == 0;
    final double percentRecebido = isEmpty ? 0 : (recebido / previsto * 100).clamp(0, 100);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: isEmpty
                          ? [PieChartSectionData(value: 1, color: EagleTokens.textSecondary.withValues(alpha: 0.3), radius: 20, showTitle: false)]
                          : [
                              PieChartSectionData(
                                value: recebido,
                                color: EagleTokens.success,
                                radius: 24,
                                showTitle: false,
                              ),
                              if (pendente > 0)
                                PieChartSectionData(
                                  value: pendente,
                                  color: EagleTokens.warning.withValues(alpha: 0.5),
                                  radius: 20,
                                  showTitle: false,
                                ),
                            ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${percentRecebido.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const Text('Recebido', style: TextStyle(fontSize: 12, color: EagleTokens.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            if (!isEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(color: EagleTokens.success, label: 'Recebido'),
                  const SizedBox(width: 16),
                  _LegendItem(color: EagleTokens.warning.withValues(alpha: 0.5), label: 'Pendente'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: EagleTokens.textSecondary)),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.15),
          child: Icon(icone, color: cor),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ),
    );
  }
}
