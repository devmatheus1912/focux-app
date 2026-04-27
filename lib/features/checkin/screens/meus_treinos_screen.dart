import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';

class MeusTreinosScreen extends ConsumerWidget {
  const MeusTreinosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(meusTreinosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: treinosAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: primary)),
          error: (e, _) => _TrainingEmptyState(
            title: 'Nao foi possivel carregar',
            message: 'Toque para tentar novamente.',
            icon: Icons.wifi_off_rounded,
            isDark: isDark,
            onTap: () => ref.invalidate(meusTreinosProvider),
          ),
          data: (treinos) {
            if (treinos.isEmpty) {
              return _TrainingEmptyState(
                title: 'Nenhum treino atribuido',
                message:
                    'Assim que seu personal liberar um treino, ele aparece aqui com execucao guiada.',
                icon: Icons.fitness_center_outlined,
                isDark: isDark,
              );
            }

            final ativos = treinos.where((t) => t.status.toUpperCase() != 'CONCLUIDO').length;
            final totalExercicios = treinos.fold<int>(0, (sum, t) => sum + t.exercicios.length);
            final totalConcluidos = treinos.fold<int>(
              0,
              (sum, t) => sum + t.exercicios.where((e) => e.concluido).length,
            );

            return RefreshIndicator(
              color: primary,
              onRefresh: () async => ref.invalidate(meusTreinosProvider),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard/aluno'),
                            icon: Icon(Icons.arrow_back_rounded, color: ink),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TREINOS',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sua rotina',
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => ref.invalidate(meusTreinosProvider),
                            icon: Icon(Icons.refresh_rounded, color: mute),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: _TrainingHero(
                        ativos: ativos,
                        total: treinos.length,
                        totalExercicios: totalExercicios,
                        totalConcluidos: totalConcluidos,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: treinos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _TrainingPlanCard(
                        treino: treinos[index],
                        isDark: isDark,
                        onStart: () => context.push(
                          '/checkin/executar',
                          extra: treinos[index].treinoId,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrainingHero extends StatelessWidget {
  final int ativos;
  final int total;
  final int totalExercicios;
  final int totalConcluidos;
  final bool isDark;

  const _TrainingHero({
    required this.ativos,
    required this.total,
    required this.totalExercicios,
    required this.totalConcluidos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    final progresso = totalExercicios == 0 ? 0.0 : totalConcluidos / totalExercicios;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.18 : 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$ativos treino${ativos == 1 ? '' : 's'} ativo${ativos == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$total no plano atual',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$totalConcluidos de $totalExercicios exercicios concluidos no ciclo aberto.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingPlanCard extends StatelessWidget {
  final ExecucaoTreino treino;
  final bool isDark;
  final VoidCallback onStart;

  const _TrainingPlanCard({
    required this.treino,
    required this.isDark,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final done = treino.exercicios.where((e) => e.concluido).length;
    final progress = treino.exercicios.isEmpty ? 0.0 : done / treino.exercicios.length;
    final mediaCount = treino.exercicios.where((e) => e.gifUrl?.isNotEmpty == true).length;
    final status = treino.status.toUpperCase();
    final concluido = status == 'CONCLUIDO';

    return InkWell(
      onTap: onStart,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: concluido ? EagleTokens.good : line, width: concluido ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: concluido
                        ? EagleTokens.good.withValues(alpha: 0.12)
                        : BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    concluido ? Icons.check_rounded : Icons.fitness_center_rounded,
                    color: concluido ? EagleTokens.good : primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treino.treinoNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _PlanMeta(icon: Icons.list_alt_rounded, text: '${treino.exercicios.length} exercicios', color: mute),
                          if (mediaCount > 0)
                            _PlanMeta(icon: Icons.play_circle_outline_rounded, text: '$mediaCount videos', color: mute),
                          _PlanMeta(icon: Icons.timer_outlined, text: '~${(treino.exercicios.length * 4).clamp(8, 90)}min', color: mute),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mute),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                valueColor: AlwaysStoppedAnimation(concluido ? EagleTokens.good : primary),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    concluido
                        ? 'Treino finalizado. Historico salvo.'
                        : done == 0
                            ? 'Pronto para iniciar com registro de series.'
                            : '$done de ${treino.exercicios.length} exercicios ja marcados.',
                    style: TextStyle(
                      color: mute,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: Icon(concluido ? Icons.replay_rounded : Icons.play_arrow_rounded, size: 18),
                  label: Text(concluido ? 'Rever' : 'Iniciar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _PlanMeta({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TrainingEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _TrainingEmptyState({
    required this.title,
    required this.message,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
