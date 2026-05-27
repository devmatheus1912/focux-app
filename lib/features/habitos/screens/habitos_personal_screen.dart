import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/habito_repository.dart';

final _repoProvider = Provider(
  (ref) => HabitoRepository(ref.read(apiClientProvider)),
);

class HabitosPersonalScreen extends ConsumerStatefulWidget {
  const HabitosPersonalScreen({super.key});

  @override
  ConsumerState<HabitosPersonalScreen> createState() =>
      _HabitosPersonalScreenState();
}

class _HabitosPersonalScreenState extends ConsumerState<HabitosPersonalScreen> {
  List<Habito> _habitos = [];
  List<ComplianceItem> _compliance = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(_repoProvider);
      final results = await Future.wait([repo.listar(), repo.compliance()]);
      if (!mounted) return;
      setState(() {
        _habitos = results[0] as List<Habito>;
        _compliance = results[1] as List<ComplianceItem>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _novoHabito() async {
    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo hábito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (ok == true && tituloCtrl.text.trim().isNotEmpty) {
      try {
        await ref.read(_repoProvider).criar(
              titulo: tituloCtrl.text.trim(),
              descricao: descricaoCtrl.text.trim().isEmpty
                  ? null
                  : descricaoCtrl.text.trim(),
            );
        await _carregar();
      } catch (e) {
        if (!mounted) return;
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hábitos & Compliance')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoHabito,
        icon: const Icon(Icons.add),
        label: const Text('Novo hábito'),
      ),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader(
                    titulo: 'Hábitos cadastrados',
                    subtitulo: 'Aplica para todos os seus alunos',
                  ),
                  if (_habitos.isEmpty)
                    const _EmptyHabitos()
                  else
                    ..._habitos.map(
                      (h) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(h.titulo),
                          subtitle: Text(h.descricao ?? 'Meta semanal: ${h.metaSemanal}x'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref.read(_repoProvider).desativar(h.id);
                              await _carregar();
                            },
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    titulo: 'Compliance da semana',
                    subtitulo: 'Aderência dos seus alunos aos hábitos',
                  ),
                  if (_compliance.isEmpty)
                    Card(
                      child: const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Sem dados ainda'),
                        subtitle: Text('Cadastre hábitos e os alunos vão começar a marcar.'),
                      ),
                    )
                  else
                    ..._compliance.map((c) => _ComplianceTile(item: c)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.titulo, required this.subtitulo});
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800)),
          Text(subtitulo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}

class _EmptyHabitos extends StatelessWidget {
  const _EmptyHabitos();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.checklist_outlined, size: 40),
            const SizedBox(height: 8),
            Text('Nenhum hábito cadastrado',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Hábitos diários (água, sono, refeições) aumentam aderência em 25-40% e reduzem churn (HAVIT, Everfit benchmark 2026).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplianceTile extends StatelessWidget {
  const _ComplianceTile({required this.item});
  final ComplianceItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.compliancePct >= 70
        ? Colors.green
        : item.compliancePct >= 40
            ? Colors.orange
            : Colors.red;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .15),
          child: Text('${item.compliancePct}%',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        title: Text(item.alunoNome),
        subtitle: Text('${item.checksSemana} checks na semana'),
        trailing: Icon(
          item.compliancePct >= 70
              ? Icons.trending_up
              : Icons.trending_down,
          color: color,
        ),
      ),
    );
  }
}
