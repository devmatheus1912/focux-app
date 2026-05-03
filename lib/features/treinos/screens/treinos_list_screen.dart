import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';
import '../../../core/widgets/skeleton_loader.dart';

class TreinosListScreen extends ConsumerWidget {
  final int? alunoId;
  final String? alunoNome;
  const TreinosListScreen({super.key, this.alunoId, this.alunoNome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync =
        alunoId == null
            ? ref.watch(treinosProvider)
            : ref.watch(treinosDoAlunoProvider(alunoId!));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 72,
        ), // clear FxDock (70px + 18px bottom)
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, BrandPalette.deep(primary)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () async {
              final criado = await context.push<bool>(
                '/treinos/novo',
                extra:
                    alunoId == null
                        ? null
                        : {'alunoId': alunoId, 'alunoNome': alunoNome},
              );
              if (criado == true) {
                if (alunoId == null) {
                  ref.invalidate(treinosProvider);
                } else {
                  ref.invalidate(treinosDoAlunoProvider(alunoId!));
                }
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
      body: treinosAsync.when(
        loading: () => const SkeletonList(count: 5),
        error:
            (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: mute),
                  const SizedBox(height: 12),
                  Text('Erro ao carregar', style: TextStyle(color: mute)),
                ],
              ),
            ),
        data:
            (treinos) => SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${treinos.length} ATIVOS',
                              style: TextStyle(
                                fontSize: 12,
                                color: mute,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alunoId == null
                                  ? 'Treinos'
                                  : 'Treinos de ${alunoNome ?? 'Aluno'}',
                              style: TextStyle(
                                fontSize: 32,
                                color: ink,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: mute),
                          onPressed:
                              () => safePopOrGo(
                                context,
                                alunoId == null
                                    ? '/treinos'
                                    : '/alunos/$alunoId',
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        treinos.isEmpty
                            ? _EmptyState(isDark: isDark, primary: primary)
                            : RefreshIndicator(
                              color: primary,
                              onRefresh: () async {
                                if (alunoId == null) {
                                  ref.invalidate(treinosProvider);
                                } else {
                                  ref.invalidate(
                                    treinosDoAlunoProvider(alunoId!),
                                  );
                                }
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  100,
                                ),
                                itemCount: treinos.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 10),
                                itemBuilder:
                                    (context, i) => _TreinoCard(
                                      treino: treinos[i],
                                      isDark: isDark,
                                      primary: primary,
                                    ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  const _EmptyState({required this.isDark, required this.primary});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.fitness_center, color: primary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Nenhum treino',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Crie seu primeiro treino\npara seus alunos.',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _TreinoCard extends StatelessWidget {
  final Treino treino;
  final bool isDark;
  final Color primary;
  const _TreinoCard({
    required this.treino,
    required this.isDark,
    required this.primary,
  });

  IconData get _nivelIcon {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO':
        return Icons.local_fire_department;
      case 'INTERMEDIARIO':
        return Icons.speed;
      default:
        return Icons.eco;
    }
  }

  Color get _nivelColor {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO':
        return EagleTokens.bad;
      case 'INTERMEDIARIO':
        return EagleTokens.warn;
      default:
        return EagleTokens.good;
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
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.fitness_center, color: primary, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          treino.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color:
                                isDark ? EagleTokens.darkInk : EagleTokens.ink,
                          ),
                        ),
                      ),
                      if (treino.isTemplate)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Template',
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 14,
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${treino.exercicios.length} exercício(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
                        ),
                      ),
                      if (treino.nivel != null) ...[
                        const SizedBox(width: 12),
                        Icon(_nivelIcon, size: 14, color: _nivelColor),
                        const SizedBox(width: 4),
                        Text(
                          treino.nivel!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _nivelColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
