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
                  value: 'excluir',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Excluir treino', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
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
        data: (treino) {
          final repo = ref.read(treinoRepositoryProvider);
          
          // Agrupamento por músculo alvo
          final grouped = <String, List<TreinoExercicioItem>>{};
          for (final te in treino.exercicios) {
            final group = te.exercicio.musculoAlvo?.isNotEmpty == true ? te.exercicio.musculoAlvo! : 'Outros';
            grouped.putIfAbsent(group, () => []).add(te);
          }

          return CustomScrollView(
            slivers: [
              // Hero Gradient Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.fitness_center, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(treino.nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                if (treino.objetivo?.isNotEmpty == true)
                                  Text(treino.objetivo!, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _HeaderChip(icon: Icons.list_alt, label: '${treino.exercicios.length} exercícios'),
                          const SizedBox(width: 8),
                          if (treino.nivel != null) _HeaderChip(icon: Icons.speed, label: treino.nivel!),
                          if (treino.isTemplate) ...[
                            const SizedBox(width: 8),
                            const _HeaderChip(icon: Icons.bookmark, label: 'Template'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Iniciar Treino Button (Overlap)
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton.icon(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text('Iniciar Treino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              
              // Lista de exercícios agrupada
              if (treino.exercicios.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('Nenhum exercício no treino.')))
              else
                ...grouped.entries.map((entry) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SectionHeaderDelegate(title: entry.key.toUpperCase()),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final te = entry.value[index];
                            return _ExercicioCard(
                              te: te,
                              onRemove: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remover exercício'),
                                    content: Text('Remover "${te.exercicio.nome}" do treino?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                      FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  try {
                                    await repo.removerExercicio(treinoId, te.id);
                                    ref.invalidate(treinoProvider(treinoId));
                                  } catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                                  }
                                }
                              },
                            );
                          },
                          childCount: entry.value.length,
                        ),
                      ),
                    ],
                  );
                }),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
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
    } else if (action == 'excluir') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir treino'),
          content: Text('Tem certeza que deseja excluir "${treino.nome}"? Esta ação não pode ser desfeita.'),
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
      if (confirm == true && context.mounted) {
        try {
          await repo.excluirTreino(treinoId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Treino excluído!')),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
          }
        }
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

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  _SectionHeaderDelegate({required this.title});

  @override
  double get minExtent => 40;
  @override
  double get maxExtent => 40;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class _ExercicioCard extends StatelessWidget {
  final TreinoExercicioItem te;
  final VoidCallback onRemove;
  const _ExercicioCard({required this.te, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.fitness_center),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(te.exercicio.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      Text('${te.series}x${te.repeticoes}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      if (te.cargaKg != null) Text('· ${te.cargaKg}kg', style: const TextStyle(color: Colors.grey)),
                      if (te.descansoSegundos != null) Text('· ${te.descansoSegundos}s', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'remove', child: Text('Remover', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
