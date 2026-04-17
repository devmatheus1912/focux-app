import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';

class TreinoDetailScreen extends ConsumerWidget {
  final int treinoId;
  const TreinoDetailScreen({super.key, required this.treinoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinoAsync = ref.watch(treinoProvider(treinoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar exercício',
            onPressed: () async {
              final adicionado = await context.push<bool>(
                  '/treinos/$treinoId/exercicios/add');
              if (adicionado == true) ref.invalidate(treinoProvider(treinoId));
            },
          ),
          treinoAsync.when(
            data: (treino) => PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenu(context, ref, value, treino),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'template',
                  child: ListTile(
                    leading: Icon(Icons.bookmark_add_outlined),
                    title: Text('Salvar como template'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicar',
                  child: ListTile(
                    leading: Icon(Icons.copy_outlined),
                    title: Text('Duplicar treino'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'clonar',
                  child: ListTile(
                    leading: Icon(Icons.person_add_outlined),
                    title: Text('Clonar para aluno'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: treinoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (treino) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(treino.nome,
                            style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      if (treino.isTemplate)
                        const Chip(
                          label: Text('Template'),
                          avatar: Icon(Icons.bookmark, size: 14),
                        ),
                    ],
                  ),
                  if (treino.nivel != null) Chip(label: Text(treino.nivel!)),
                  if (treino.objetivo != null)
                    Text(treino.objetivo!,
                        style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: treino.exercicios.isEmpty
                  ? const Center(child: Text('Nenhum exercício no treino.'))
                  : ListView.builder(
                      itemCount: treino.exercicios.length,
                      itemBuilder: (context, i) {
                        final te = treino.exercicios[i];
                        return ListTile(
                          leading: Text('${i + 1}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          title: Text(te.exercicio.nome),
                          subtitle: Text('${te.series}x${te.repeticoes}'
                              '${te.cargaKg != null ? ' · ${te.cargaKg}kg' : ''}'),
                          trailing: te.descansoSegundos != null
                              ? Text('${te.descansoSegundos}s',
                                  style:
                                      const TextStyle(color: Colors.grey))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenu(
      BuildContext context, WidgetRef ref, String action, Treino treino) async {
    final repo = ref.read(treinoRepositoryProvider);

    if (action == 'template') {
      try {
        await repo.salvarComoTemplate(treinoId);
        ref.invalidate(treinoProvider(treinoId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Treino salvo como template!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    } else if (action == 'duplicar') {
      try {
        await repo.duplicar(treinoId);
        ref.invalidate(treinosProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Treino duplicado com sucesso!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    } else if (action == 'clonar') {
      if (context.mounted) {
        await _showClonarDialog(context, ref, repo);
      }
    }
  }

  Future<void> _showClonarDialog(
      BuildContext context, WidgetRef ref, TreinoRepository repo) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clonar para aluno'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ID do aluno',
            hintText: 'Ex: 42',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clonar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final alunoId = int.tryParse(controller.text.trim());
      if (alunoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID inválido')),
        );
        return;
      }
      try {
        await repo.clonarParaAluno(treinoId, alunoId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Treino clonado para o aluno!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }
}
