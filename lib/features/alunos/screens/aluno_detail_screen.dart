import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/alunos_provider.dart';
import '../../anamnese/screens/anamnese_screen.dart';
import '../../avaliacao/screens/avaliacao_screen.dart';
import '../../alimentar/screens/alimentar_screen.dart';
import '../../ia/screens/ia_screen.dart';
import '../../ia/screens/ia_progressao_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../relatorio/screens/relatorio_screen.dart';
import '../../financeiro/data/financeiro_repository.dart';

class AlunoDetailScreen extends ConsumerWidget {
  final int alunoId;
  const AlunoDetailScreen({super.key, required this.alunoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    return Scaffold(
      appBar: AppBar(title: const Text('Aluno')),
      body: alunoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: CircleAvatar(radius: 40,
              child: Text(aluno.nome[0].toUpperCase(), style: const TextStyle(fontSize: 32)))),
            const SizedBox(height: 12),
            Center(child: Text(aluno.nome, style: Theme.of(context).textTheme.headlineSmall)),
            Center(child: Text(aluno.email, style: const TextStyle(color: Colors.grey))),
            if (aluno.inadimplente) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Text('Mensalidade em atraso', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              _InfoRow(label: 'Status', value: aluno.status),
              if (aluno.objetivo != null && aluno.objetivo!.isNotEmpty)
                _InfoRow(label: 'Objetivo', value: aluno.objetivo!),
            ]))),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _MenuBtn(icon: Icons.assignment, label: 'Anamnese',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AnamneseScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.monitor_weight, label: 'Avaliação Física',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AvaliacaoScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.restaurant_menu, label: 'Plano Alimentar',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AlimentarScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.bar_chart, label: 'Relatório de Aderência',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RelatorioScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
            _MenuBtn(icon: Icons.receipt_long, label: 'Histórico de Mensalidades',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _HistoricoMensalidadesScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
            _MenuBtn(icon: Icons.auto_awesome, label: 'Gerar Treino/Dieta com IA',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => IaScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.trending_up, label: 'Progressão de Carga com IA',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => IaProgressaoScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
            _MenuBtn(icon: Icons.chat, label: 'Chat',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
          ]),
        ),
      ),
    );
  }
}

class _HistoricoMensalidadesScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const _HistoricoMensalidadesScreen({required this.alunoId, required this.alunoNome});

  @override
  ConsumerState<_HistoricoMensalidadesScreen> createState() => _HistoricoMensalidadesScreenState();
}

class _HistoricoMensalidadesScreenState extends ConsumerState<_HistoricoMensalidadesScreen> {
  List<Mensalidade> _mensalidades = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await FinanceiroRepository(ref.read(apiClientProvider))
          .listarPorAluno(widget.alunoId);
      if (mounted) setState(() { _mensalidades = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAGO': return Colors.green;
      case 'ATRASADO': return Colors.red;
      default: return Colors.orange;
    }
  }

  Future<void> _registrarContato(Mensalidade m) async {
    const tipos = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
    String? tipoSelecionado = tipos.first;
    final obsCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Registrar Contato'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: tipoSelecionado,
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
              items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => set(() => tipoSelecionado = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(labelText: 'Observação (opcional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar')),
          ],
        ),
      ),
    );
    if (confirm != true || tipoSelecionado == null) return;
    try {
      await FinanceiroRepository(ref.read(apiClientProvider))
          .registrarContato(m.id, tipoSelecionado!, obsCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contato registrado!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Mensalidades — ${widget.alunoNome}'),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _mensalidades.isEmpty
            ? const Center(child: Text('Nenhuma mensalidade registrada.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _mensalidades.length,
                itemBuilder: (_, i) {
                  final m = _mensalidades[i];
                  final color = _statusColor(m.status);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(m.mesReferencia.substring(0, 7),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('R\$ ${m.valor.toStringAsFixed(2)}${m.pagoEm != null ? " · pago ${m.pagoEm!.substring(0, 10)}" : ""}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Chip(
                          label: Text(m.status, style: TextStyle(color: color, fontSize: 11)),
                          backgroundColor: color.withValues(alpha: 0.12),
                        ),
                        if (m.status != 'PAGO')
                          IconButton(
                            icon: const Icon(Icons.phone_in_talk, size: 20),
                            tooltip: 'Registrar contato',
                            onPressed: () => _registrarContato(m),
                          ),
                      ]),
                    ),
                  );
                },
              ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    ]),
  );
}

class _MenuBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MenuBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(leading: Icon(icon), title: Text(label),
      trailing: const Icon(Icons.chevron_right), onTap: onTap),
  );
}
