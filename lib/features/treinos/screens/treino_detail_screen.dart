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
          expandedHeight: 320,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF0A0F1E) : EagleTokens.brandDeep,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Sugestão IA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [const Color(0xFF1C3273), const Color(0xFF0A0F1E)]
                      : [EagleTokens.brand, EagleTokens.brandDeep],
                  stops: const [0.0, 0.85],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 100, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cover tile & Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 108, height: 108,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 12))],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.fitness_center, size: 56, color: Colors.white.withValues(alpha: 0.9)),
                            Positioned(
                              bottom: 8, left: 10,
                              child: Text('TREINO', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ALUNO FOCO', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                              const SizedBox(height: 2),
                              Text(treino.nome, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.1)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 13, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text('45min', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Text('·', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Text('${treino.exercicios.length} ex.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  
                  // Action row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => HapticFeedback.mediumImpact(),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: EagleTokens.brand, size: 20),
                                const SizedBox(width: 6),
                                Text('Iniciar treino', style: TextStyle(color: EagleTokens.brand, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          // TODO: Show bottom sheet for menu options
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ),

        // Stats Ribbon
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                _MiniMetric(label: 'Nível', value: treino.nivel ?? 'Interm.', isDark: isDark),
                const SizedBox(width: 8),
                _MiniMetric(label: 'Grupos', value: '${grouped.keys.length}', isDark: isDark),
                const SizedBox(width: 8),
                _MiniMetric(label: 'Última', value: 'Qua 15/4', isDark: isDark),
              ],
            ),
          ),
        ),

        // Exercise list grouped
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Exercícios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.darkInk : EagleTokens.ink, letterSpacing: -0.5)),
                InkWell(
                  onTap: () async {
                    final adicionado = await context.push<bool>('/treinos/$treinoId/exercicios/add');
                    if (adicionado == true) ref.invalidate(treinoProvider(treinoId));
                  },
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand),
                      const SizedBox(width: 4),
                      Text('Adicionar', style: TextStyle(color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (treino.exercicios.isEmpty)
          const SliverFillRemaining(child: Center(child: Text('Nenhum exercício no treino.')))
        else
          ...grouped.entries.map((entry) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                        child: Row(
                          children: [
                            Text(entry.key.toUpperCase(), style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                            const SizedBox(width: 8),
                            Expanded(child: Container(height: 0.5, color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                            const SizedBox(width: 8),
                            Text('${entry.value.length} ex.', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                          borderRadius: BorderRadius.circular(20),
                          border: isDark ? null : Border.all(color: EagleTokens.line),
                        ),
                        child: Column(
                          children: entry.value.asMap().entries.map((e) {
                            final i = e.key;
                            final te = e.value;
                            return _ExercicioRow(
                              te: te,
                              index: i + 1,
                              isDark: isDark,
                              isLast: i == entry.value.length - 1,
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
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniMetric({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCard : EagleTokens.card,
          borderRadius: BorderRadius.circular(14),
          border: isDark ? null : Border.all(color: EagleTokens.line),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

class _ExercicioRow extends StatelessWidget {
  final TreinoExercicioItem te;
  final int index;
  final bool isDark;
  final bool isLast;
  final VoidCallback onRemove;

  const _ExercicioRow({
    required this.te,
    required this.index,
    required this.isDark,
    required this.isLast,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0x1F8DA4E2) : EagleTokens.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('$index', style: TextStyle(color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(te.exercicio.nome, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${te.series}×${te.repeticoes}', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: BoxDecoration(color: mute, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('${te.cargaKg ?? 0}kg', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: BoxDecoration(color: mute, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 11, color: mute),
                    const SizedBox(width: 3),
                    Text('${te.descansoSegundos ?? 60}s', style: TextStyle(color: mute, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconColor: mute,
            iconSize: 20,
            onSelected: (val) { if (val == 'remove') onRemove(); },
            itemBuilder: (_) => [const PopupMenuItem(value: 'remove', child: Text('Remover', style: TextStyle(color: EagleTokens.bad)))],
          ),
        ],
      ),
    );
  }
}
