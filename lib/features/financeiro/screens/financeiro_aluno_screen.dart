import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';

class FinanceiroAlunoScreen extends ConsumerStatefulWidget {
  const FinanceiroAlunoScreen({super.key});

  @override
  ConsumerState<FinanceiroAlunoScreen> createState() => _FinanceiroAlunoScreenState();
}

class _FinanceiroAlunoScreenState extends ConsumerState<FinanceiroAlunoScreen> {
  List<Mensalidade> _mensalidades = [];
  bool _loading = true;
  String? _erro;

  static const _mesesNomes = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final result = await FinanceiroRepository(ref.read(apiClientProvider))
          .minhasMensalidades();
      if (mounted) setState(() { _mensalidades = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAGO': return Colors.green;
      case 'ATRASADO': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _formatarMes(String mesReferencia) {
    // mesReferencia format: "2026-04-01"
    try {
      final parts = mesReferencia.split('-');
      if (parts.length < 2) return mesReferencia;
      final ano = parts[0];
      final mes = int.parse(parts[1]);
      if (mes < 1 || mes > 12) return mesReferencia;
      return '${_mesesNomes[mes]} $ano';
    } catch (_) {
      return mesReferencia;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Mensalidades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Erro ao carregar mensalidades',
                            style: TextStyle(color: cs.error, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_erro!, style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _mensalidades.isEmpty
                  ? const Center(child: Text('Nenhuma mensalidade encontrada.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _mensalidades.length,
                      itemBuilder: (_, i) {
                        final m = _mensalidades[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatarMes(m.mesReferencia),
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'R\$ ${m.valor.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 15, color: cs.onSurfaceVariant),
                                      ),
                                      if (m.pagoEm != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pago em: ${m.pagoEm}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.green),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(m.status),
                                  backgroundColor:
                                      _statusColor(m.status).withValues(alpha: 0.15),
                                  labelStyle: TextStyle(
                                      color: _statusColor(m.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
