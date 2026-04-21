import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../anamnese/screens/anamnese_screen.dart';
import '../../avaliacao/screens/avaliacao_screen.dart';
import '../../alimentar/screens/alimentar_screen.dart';
import '../../ia/screens/ia_screen.dart';
import '../../ia/screens/ia_progressao_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../relatorio/screens/relatorio_screen.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../evolucao/screens/evolucao_screen.dart';
import '../../evolucao/data/evolucao_repository.dart';

class AlunoDetailScreen extends ConsumerWidget {
  final int alunoId;
  const AlunoDetailScreen({super.key, required this.alunoId});

  Future<void> _confirmarExclusao(BuildContext context, WidgetRef ref, Aluno aluno) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text('Tem certeza que deseja excluir ${aluno.nome}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await AlunoRepository(ref.read(apiClientProvider)).excluirAluno(aluno.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno excluído.')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));

    final appBar = alunoAsync.when(
      data: (aluno) => AppBar(
        title: Text(aluno.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () async {
              final updated = await context.push<bool>('/alunos/$alunoId/editar', extra: aluno);
              if (updated == true) ref.invalidate(alunoProvider(alunoId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
            onPressed: () => _confirmarExclusao(context, ref, aluno),
          ),
        ],
      ),
      loading: () => AppBar(title: const Text('Aluno')),
      error: (_, __) => AppBar(title: const Text('Aluno')),
    );

    return Scaffold(
      appBar: appBar,
      body: alunoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) => SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Hero Gradient Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(top: 24, bottom: 40, left: 16, right: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : 'A', 
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text(aluno.nome, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(aluno.objetivo ?? aluno.email, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  _StatusBadge(status: aluno.status, statusFinanceiro: aluno.statusFinanceiro),
                ],
              ),
            ),
            
            // Transform upward to overlap
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row (Aderência, etc)
                    _SecaoEngajamento(alunoId: alunoId),
                    const SizedBox(height: 24),
                    
                    Text('Ferramentas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // Grid Ferramentas
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        _GridToolBtn(icon: Icons.monitor_weight, label: 'Avaliação Física', color: Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AvaliacaoScreen(alunoId: alunoId)))),
                        _GridToolBtn(icon: Icons.assignment, label: 'Anamnese', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnamneseScreen(alunoId: alunoId)))),
                        _GridToolBtn(icon: Icons.restaurant_menu, label: 'Dieta', color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlimentarScreen(alunoId: alunoId)))),
                        _GridToolBtn(icon: Icons.show_chart, label: 'Evolução', color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EvolucaoScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
                        _GridToolBtn(icon: Icons.bar_chart, label: 'Aderência', color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RelatorioScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
                        _GridToolBtn(icon: Icons.receipt_long, label: 'Financeiro', color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _HistoricoMensalidadesScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text('Inteligência Artificial', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    _MenuBtn(icon: Icons.auto_awesome, label: 'Gerar Treino/Dieta', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IaScreen(alunoId: alunoId)))),
                    _MenuBtn(icon: Icons.trending_up, label: 'Progressão de Carga', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IaProgressaoScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
                    const SizedBox(height: 24),
                    
                    Text('Comunicação', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _MenuBtn(icon: Icons.chat, label: 'Chat com Aluno', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String statusFinanceiro;
  const _StatusBadge({required this.status, required this.statusFinanceiro});

  @override
  Widget build(BuildContext context) {
    Color cor;
    IconData icone;
    String texto;
    if (statusFinanceiro == 'INADIMPLENTE') {
      cor = const Color(0xFFE53935);
      icone = Icons.warning_amber_rounded;
      texto = 'Inadimplente';
    } else if (status == 'INATIVO') {
      cor = const Color(0xFFFFA726);
      icone = Icons.pause_circle_outline;
      texto = 'Inativo';
    } else {
      cor = const Color(0xFF43A047);
      icone = Icons.check_circle_outline;
      texto = 'Ativo';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icone, color: cor, size: 16),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
      ]),
    );
  }
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

class _SecaoEngajamento extends ConsumerStatefulWidget {
  final int alunoId;
  const _SecaoEngajamento({required this.alunoId});

  @override
  ConsumerState<_SecaoEngajamento> createState() => _SecaoEngajamentoState();
}

class _SecaoEngajamentoState extends ConsumerState<_SecaoEngajamento> {
  Map<String, dynamic>? _dados;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final repo = EvolucaoRepository(ref.read(apiClientProvider));
      final r = await repo.engajamentoResumo(widget.alunoId);
      if (mounted) setState(() { _dados = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Text('Erro ao carregar engajamento: $_erro',
          style: const TextStyle(color: Colors.red, fontSize: 12));
    }
    if (_dados == null) return const SizedBox.shrink();

    final totalTreinos = _dados!['totalTreinos'] ?? 0;
    final treinosMes = _dados!['treinosMes'] ?? 0;
    final aderencia = _dados!['aderencia'] ?? 0;
    final diasSemTreinar = _dados!['diasSemTreino'] ?? _dados!['diasSemTreinar'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 12, runSpacing: 12, children: [
          _StatEngajamento(label: 'Total Treinos', valor: totalTreinos.toString()),
          _StatEngajamento(label: 'Treinos/Mês', valor: treinosMes.toString()),
          _StatEngajamento(
            label: 'Aderência',
            valor: '$aderencia%',
            cor: aderencia >= 70 ? Colors.green : (aderencia >= 40 ? Colors.orange : Colors.red),
          ),
          _StatEngajamento(
            label: 'Dias sem treinar',
            valor: diasSemTreinar.toString(),
            cor: diasSemTreinar > 7 ? Colors.red : Colors.green,
          ),
        ]),
      ),
    );
  }
}

class _StatEngajamento extends StatelessWidget {
  final String label, valor;
  final Color? cor;
  const _StatEngajamento({required this.label, required this.valor, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Theme.of(context).colorScheme.primary;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: c)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _GridToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridToolBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
