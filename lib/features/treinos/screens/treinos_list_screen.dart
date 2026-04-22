import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';

class TreinosListScreen extends ConsumerWidget {
  const TreinosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(treinosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Treinos', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontWeight: FontWeight.w700, fontSize: 22)),
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandInk]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final criado = await context.push<bool>('/treinos/novo');
            if (criado == true) ref.invalidate(treinosProvider);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: treinosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EagleTokens.brand)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
            const SizedBox(height: 12),
            Text('Erro ao carregar', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute)),
          ]),
        ),
        data: (treinos) => treinos.isEmpty
            ? _EmptyState(isDark: isDark)
            : RefreshIndicator(
                color: EagleTokens.brand,
                onRefresh: () async => ref.invalidate(treinosProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: treinos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _TreinoCard(treino: treinos[i], isDark: isDark),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.fitness_center, color: EagleTokens.brand, size: 32),
      ),
      const SizedBox(height: 16),
      Text('Nenhum treino', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Crie seu primeiro treino\npara seus alunos.', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 14), textAlign: TextAlign.center),
    ]),
  );
}

class _TreinoCard extends StatelessWidget {
  final Treino treino;
  final bool isDark;
  const _TreinoCard({required this.treino, required this.isDark});

  IconData get _nivelIcon {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO': return Icons.local_fire_department;
      case 'INTERMEDIARIO': return Icons.speed;
      default: return Icons.eco;
    }
  }

  Color get _nivelColor {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO': return EagleTokens.bad;
      case 'INTERMEDIARIO': return EagleTokens.warn;
      default: return EagleTokens.good;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/treinos/${treino.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCard : EagleTokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: EagleTokens.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center, color: EagleTokens.brand, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(treino.nome, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? EagleTokens.darkInk : EagleTokens.ink))),
                    if (treino.isTemplate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Template', style: TextStyle(color: EagleTokens.brand, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.list_alt, size: 14, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
                    const SizedBox(width: 4),
                    Text('${treino.exercicios.length} exercício(s)', style: TextStyle(fontSize: 12, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute)),
                    if (treino.nivel != null) ...[
                      const SizedBox(width: 12),
                      Icon(_nivelIcon, size: 14, color: _nivelColor),
                      const SizedBox(width: 4),
                      Text(treino.nivel!, style: TextStyle(fontSize: 12, color: _nivelColor, fontWeight: FontWeight.w500)),
                    ],
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, size: 20),
          ],
        ),
      ),
    );
  }
}
