import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key});
  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen> {
  List<Mensalidade> _mensalidades = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await FinanceiroRepository(ref.read(apiClientProvider)).listar();
      setState(() { _mensalidades = r; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAGO': return Colors.green;
      case 'ATRASADO': return Colors.red;
      default: return Colors.orange;
    }
  }

  Future<void> _pagar(int id) async {
    try {
      await FinanceiroRepository(ref.read(apiClientProvider)).pagar(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Financeiro')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _mensalidades.isEmpty
            ? const Center(child: Text('Nenhuma mensalidade lançada.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _mensalidades.length,
                itemBuilder: (_, i) {
                  final m = _mensalidades[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(m.alunoNome),
                      subtitle: Text('${m.mesReferencia.substring(0, 7)} • R\$ ${m.valor.toStringAsFixed(2)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Chip(label: Text(m.status),
                          backgroundColor: _statusColor(m.status).withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: _statusColor(m.status), fontSize: 12)),
                        if (m.status == 'PENDENTE' || m.status == 'ATRASADO')
                          IconButton(icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _pagar(m.id)),
                      ]),
                    ),
                  );
                },
              ),
  );
}
