import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      body: treinoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EagleTokens.brand)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (treino) => _TreinoDetailBody(treino: treino, treinoId: treinoId, isDark: isDark, ref: ref),
      ),
    );
  }
}

class _TreinoDetailBody extends StatelessWidget {
  final Treino treino;
  final int treinoId;
  final bool isDark;
  final WidgetRef ref;
  const _TreinoDetailBody({required this.treino, required this.treinoId, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(treinoRepositoryProvider);

    // Group by muscle
    final grouped = <String, List<TreinoExercicioItem>>{};
    for (final te in treino.exercicios) {
      final group = te.exercicio.musculoAlvo?.isNotEmpty == true ? te.exercicio.musculoAlvo! : 'Outros';
      grouped.putIfAbsent(group, () => []).add(te);
    }

    return CustomScrollView(
      slivers: [
        // Hero AppBar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.brand,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar exercício',
              onPressed: () async {
                final adicionado = await context.push<bool>('/treinos/$treinoId/exercicios/add');
                if (adicionado == true) ref.invalidate(treinoProvider(treinoId));
              },
            ),
            PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: (value) => _handleMenu(context, ref, value, treino),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'template', child: ListTile(leading: Icon(Icons.bookmark_add_outlined), title: Text('Salvar como template'), contentPadding: EdgeInsets.zero)),
                PopupMenuItem(value: 'duplicar', child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Duplicar treino'), contentPadding: EdgeInsets.zero)),
                PopupMenuItem(value: 'clonar', child: ListTile(leading: Icon(Icons.person_add_outlined), title: Text('Clonar para aluno'), contentPadding: EdgeInsets.zero)),
                PopupMenuItem(value: 'excluir', child: ListTile(leading: Icon(Icons.delete_outline, color: EagleTokens.bad), title: Text('Excluir treino', style: TextStyle(color: EagleTokens.bad)), contentPadding: EdgeInsets.zero)),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: EagleTokens.heroGradient(dark: isDark)),
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.fitness_center, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(treino.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        if (treino.objetivo?.isNotEmpty == true)
                          Text(treino.objetivo!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 16),
                  // Stats strip
                  Row(children: [
                    _StatChip(icon: Icons.list_alt, label: '${treino.exercicios.length}', sublabel: 'exercícios'),
                    const SizedBox(width: 8),
                    if (treino.nivel != null) _StatChip(icon: Icons.speed, label: treino.nivel!, sublabel: 'nível'),
                    if (treino.isTemplate) ...[const SizedBox(width: 8), const _StatChip(icon: Icons.bookmark, label: '✓', sublabel: 'template')],
                  ]),
                ],
              ),
            ),
          ),
        ),

        // Start workout button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => HapticFeedback.mediumImpact(),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Iniciar Treino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EagleTokens.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),

        // Exercise list grouped
        if (treino.exercicios.isEmpty)
          const SliverFillRemaining(child: Center(child: Text('Nenhum exercício no treino.')))
        else
          ...grouped.entries.map((entry) => SliverMainAxisGroup(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: EagleTokens.brand, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(entry.key.toUpperCase(), style: TextStyle(color: EagleTokens.brand, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
              ),
            ),
            SliverList(delegate: SliverChildBuilderDelegate(
              (context, index) {
                final te = entry.value[index];
                return _ExercicioCard(
                  te: te, isDark: isDark,
                  onRemove: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remover exercício'),
                        content: Text('Remover "${te.exercicio.nome}" do treino?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          FilledButton(style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad), onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
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
            )),
          ])),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Future<void> _handleMenu(BuildContext context, WidgetRef ref, String action, Treino treino) async {
    final repo = ref.read(treinoRepositoryProvider);

    if (action == 'template') {
      try {
        await repo.salvarComoTemplate(treinoId);
        ref.invalidate(treinoProvider(treinoId));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino salvo como template!')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } else if (action == 'duplicar') {
      try {
        await repo.duplicar(treinoId);
        ref.invalidate(treinosProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino duplicado!')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } else if (action == 'clonar') {
      if (context.mounted) await _showClonarDialog(context, ref, repo);
    } else if (action == 'excluir') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir treino'),
          content: Text('Excluir "${treino.nome}"? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad), onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        try {
          await repo.excluirTreino(treinoId);
          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino excluído!'))); Navigator.of(context).pop(); }
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  Future<void> _showClonarDialog(BuildContext context, WidgetRef ref, TreinoRepository repo) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clonar para aluno'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID do aluno', hintText: 'Ex: 42')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clonar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final alunoId = int.tryParse(controller.text.trim());
      if (alunoId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID inválido'))); return; }
      try {
        await repo.clonarParaAluno(treinoId, alunoId);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino clonado!')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  const _StatChip({required this.icon, required this.label, required this.sublabel});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 14),
      const SizedBox(width: 5),
      Text('$label ', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      Text(sublabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
    ]),
  );
}

class _ExercicioCard extends StatelessWidget {
  final TreinoExercicioItem te;
  final bool isDark;
  final VoidCallback onRemove;
  const _ExercicioCard({required this.te, required this.isDark, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.fitness_center, color: EagleTokens.brand, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(te.exercicio.nome, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? EagleTokens.darkInk : EagleTokens.ink)),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              _MiniTag(label: '${te.series}x${te.repeticoes}', color: EagleTokens.brand),
              if (te.cargaKg != null) _MiniTag(label: '${te.cargaKg}kg', color: EagleTokens.warn),
              if (te.descansoSegundos != null) _MiniTag(label: '${te.descansoSegundos}s', color: EagleTokens.good),
            ]),
          ],
        )),
        PopupMenuButton<String>(
          iconColor: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
          iconSize: 20,
          onSelected: (val) { if (val == 'remove') onRemove(); },
          itemBuilder: (_) => [const PopupMenuItem(value: 'remove', child: Text('Remover', style: TextStyle(color: EagleTokens.bad)))],
        ),
      ]),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
