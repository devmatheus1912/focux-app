import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class MeusTreinosScreen extends ConsumerWidget {
  const MeusTreinosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(meusTreinosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Sua rotina',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Sua rotina',
          subtitle: 'TREINOS',
          onBack: () => safePopOrGo(context, '/dashboard/aluno'),
          actions: [
            IconButton(
              onPressed: () => ref.invalidate(meusTreinosProvider),
              icon: Icon(Icons.refresh_rounded, color: fxScreenMute(context)),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: treinosAsync.when(
            loading: () => Center(child: FxLoading(color: primary)),
            error:
                (e, _) => _TrainingEmptyState(
                  title: 'Nao foi possivel carregar',
                  message: 'Toque para tentar novamente.',
                  icon: Icons.wifi_off_rounded,
                  isDark: isDark,
                  onTap: () => ref.invalidate(meusTreinosProvider),
                ),
            data: (treinos) {
              if (treinos.isEmpty) {
                return Column(
                  children: [
                    const Spacer(),
                    _TrainingEmptyState(
                      title: 'Nenhum treino atribuido',
                      message:
                          'Assim que seu personal liberar um treino, ele aparece aqui com execucao guiada.',
                      icon: Icons.fitness_center_outlined,
                      isDark: isDark,
                    ),
                    const Spacer(flex: 2),
                  ],
                );
              }

              final ativos =
                  treinos
                      .where((t) => t.status.toUpperCase() != 'CONCLUIDO')
                      .length;
              final totalExercicios = treinos.fold<int>(
                0,
                (sum, t) => sum + t.exercicios.length,
              );
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
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
                          18,
                        ),
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
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s5,
                        0,
                        20,
                        14,
                      ),
                      sliver: SliverList.separated(
                        itemCount: treinos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder:
                            (context, index) => _TrainingPlanCard(
                              treino: treinos[index],
                              isDark: isDark,
                              onStart:
                                  () => context.push(
                                    '/checkin/executar',
                                    extra: treinos[index].treinoId,
                                  ),
                            ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
                          110,
                        ),
                        child: _TrainingReadinessSection(
                          totalExercicios: totalExercicios,
                          totalConcluidos: totalConcluidos,
                          ativos: ativos,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
    final progresso =
        totalExercicios == 0 ? 0.0 : totalConcluidos / totalExercicios;
    final hasExercises = totalExercicios > 0;
    final headline =
        hasExercises
            ? '$ativos treino${ativos == 1 ? '' : 's'} ativo${ativos == 1 ? '' : 's'}'
            : 'Plano em montagem';
    final subtitle =
        hasExercises
            ? '$total no plano atual'
            : '$total treino${total == 1 ? '' : 's'} no plano atual';

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
                      headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
          if (hasExercises)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            )
          else
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.18,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            hasExercises
                ? '$totalConcluidos de $totalExercicios exercícios concluídos no ciclo aberto.'
                : 'A sessão já está no radar. Os exercícios aparecem aqui quando forem liberados.',
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final done = treino.exercicios.where((e) => e.concluido).length;
    final progress =
        treino.exercicios.isEmpty ? 0.0 : done / treino.exercicios.length;
    final hasExercises = treino.exercicios.isNotEmpty;
    final mediaCount =
        treino.exercicios.where((e) => e.gifUrl?.isNotEmpty == true).length;
    final status = treino.status.toUpperCase();
    final concluido = status == 'CONCLUIDO';
    void handleAction() {
      if (hasExercises || concluido) {
        onStart();
        return;
      }

      _showTrainingPendingSheet(
        context: context,
        treinoNome: treino.treinoNome,
        isDark: isDark,
      );
    }

    return InkWell(
      onTap: handleAction,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: fxListCardDecoration(
          context,
          accent: concluido ? EagleTokens.good : primary,
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
                    color:
                        concluido
                            ? EagleTokens.good.withValues(alpha: 0.12)
                            : BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    concluido
                        ? Icons.check_rounded
                        : Icons.fitness_center_rounded,
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
                          _PlanMeta(
                            icon: Icons.list_alt_rounded,
                            text:
                                hasExercises
                                    ? '${treino.exercicios.length} exercícios'
                                    : 'em preparação',
                            color: mute,
                          ),
                          if (mediaCount > 0)
                            _PlanMeta(
                              icon: Icons.play_circle_outline_rounded,
                              text: '$mediaCount videos',
                              color: mute,
                            ),
                          _PlanMeta(
                            icon: Icons.timer_outlined,
                            text:
                                '~${(treino.exercicios.length * 4).clamp(8, 90)}min',
                            color: mute,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mute),
              ],
            ),
            const SizedBox(height: 14),
            if (hasExercises)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor:
                      isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                  valueColor: AlwaysStoppedAnimation(
                    concluido ? EagleTokens.good : primary,
                  ),
                ),
              )
            else
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color:
                      isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            const SizedBox(height: 10),
            if (!hasExercises && !concluido) ...[
              Text(
                'Treino reservado. A ficha abre assim que o personal liberar os exercícios.',
                style: TextStyle(
                  color: mute,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FxLiquidPrimaryButton(
                  label: 'Ver status do treino',
                  icon: Icons.info_outline_rounded,
                  onPressed: handleAction,
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      concluido
                          ? 'Treino finalizado. Historico salvo.'
                          : done == 0
                          ? 'Pronto para iniciar com registro de séries.'
                          : '$done de ${treino.exercicios.length} exercicios ja marcados.',
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FxLiquidPrimaryButton(
                    label: concluido ? 'Rever' : 'Iniciar',
                    icon:
                        concluido
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded,
                    onPressed: handleAction,
                    expand: false,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

void _showTrainingPendingSheet({
  required BuildContext context,
  required String treinoNome,
  required bool isDark,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
  final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder:
        (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.rXl),
            child: DecoratedBox(
              decoration: fxListCardDecoration(sheetContext, accent: primary),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: BrandPalette.soft(primary, dark: isDark),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.pending_actions_rounded,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                treinoNome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Em preparacao',
                                style: TextStyle(
                                  color: mute,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      decoration: fxListCardDecoration(
                        sheetContext,
                        accent: primary,
                      ),
                      child: Text(
                        'Seu personal ja reservou este treino. Assim que os exercicios forem liberados, o botao Iniciar aparece com registro de series, videos e feedback.',
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          height: 1.42,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    SizedBox(
                      width: double.infinity,
                      child: FxLiquidPrimaryButton(
                        label: 'Entendi',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
  );
}

class _TrainingReadinessSection extends StatelessWidget {
  final int totalExercicios;
  final int totalConcluidos;
  final int ativos;
  final bool isDark;

  const _TrainingReadinessSection({
    required this.totalExercicios,
    required this.totalConcluidos,
    required this.ativos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final hasExercises = totalExercicios > 0;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasExercises ? 'Antes de treinar' : 'Próxima liberação',
            style: TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasExercises
                ? 'Entre com foco, registre as séries e finalize com feedback.'
                : 'O que falta para a sessão guiada aparecer.',
            style: TextStyle(color: mute, fontSize: 12.3, height: 1.28),
          ),
          const SizedBox(height: 14),
          if (hasExercises)
            Row(
              children: [
                Expanded(
                  child: _ReadinessPill(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Registro',
                    value: '$totalConcluidos/$totalExercicios',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ReadinessPill(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Rotina',
                    value: '$ativos ativo${ativos == 1 ? '' : 's'}',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _ReadinessMarker(
                    icon: Icons.bookmark_added_outlined,
                    title: 'Reservado',
                    state: '$ativos ativo${ativos == 1 ? '' : 's'}',
                    color: EagleTokens.good,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReadinessMarker(
                    icon: Icons.tune_rounded,
                    title: 'Ficha',
                    state: 'pendente',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReadinessMarker(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Sessão',
                    state: 'proximo',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessMarker extends StatelessWidget {
  final IconData icon;
  final String title;
  final String state;
  final Color color;
  final bool isDark;

  const _ReadinessMarker({
    required this.icon,
    required this.title,
    required this.state,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: fxListCardDecoration(context, accent: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: BrandPalette.soft(color, dark: isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            state,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mute,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _ReadinessPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s5),
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
              const SizedBox(height: TokensStrip.s4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
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
