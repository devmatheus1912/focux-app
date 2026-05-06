import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';

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

    Future<void> refresh() async {
      if (alunoId == null) {
        ref.invalidate(treinosProvider);
      } else {
        ref.invalidate(treinosDoAlunoProvider(alunoId!));
      }
    }

    Future<void> createWorkout() async {
      final criado = await context.push<bool>(
        '/treinos/novo',
        extra:
            alunoId == null
                ? null
                : {'alunoId': alunoId, 'alunoNome': alunoNome},
      );
      if (criado == true) {
        await refresh();
      }
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: treinosAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.fromLTRB(20, 86, 20, 0),
                child: SkeletonList(count: 5),
              ),
          error:
              (e, _) => _TreinosErrorState(
                isDark: isDark,
                primary: primary,
                onRetry: refresh,
              ),
          data:
              (treinos) => RefreshIndicator(
                color: primary,
                onRefresh: refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TreinosHeader(
                        treinos: treinos,
                        alunoId: alunoId,
                        alunoNome: alunoNome,
                        isDark: isDark,
                        onBack:
                            () => safePopOrGo(
                              context,
                              alunoId == null
                                  ? '/dashboard/personal'
                                  : '/alunos/$alunoId',
                            ),
                      ),
                    ),
                    if (treinos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          isDark: isDark,
                          primary: primary,
                          onCreate: createWorkout,
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: _TreinosCommandCard(
                            treinos: treinos,
                            isDark: isDark,
                            primary: primary,
                            onCreate: createWorkout,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _SectionHeader(
                            title:
                                alunoId == null
                                    ? 'Biblioteca ativa'
                                    : 'Plano do aluno',
                            action: '${treinos.length} planos',
                            isDark: isDark,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
                        sliver: SliverList.separated(
                          itemCount: treinos.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder:
                              (context, i) => _TreinoCard(
                                treino: treinos[i],
                                index: i,
                                isDark: isDark,
                                primary: primary,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

class _TreinosHeader extends StatelessWidget {
  final List<Treino> treinos;
  final int? alunoId;
  final String? alunoNome;
  final bool isDark;
  final VoidCallback onBack;

  const _TreinosHeader({
    required this.treinos,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final primary = Theme.of(context).colorScheme.primary;
    final ready = treinos.where((t) => t.exercicios.isNotEmpty).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: ink),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
              side: BorderSide(
                color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alunoId == null
                      ? '$ready PRONTOS  /  ${treinos.length} PLANOS'
                      : 'TREINOS DO ALUNO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alunoId == null
                      ? 'Treinos'
                      : alunoNome == null || alunoNome!.trim().isEmpty
                      ? 'Treinos do aluno'
                      : 'Treinos de ${alunoNome!.trim()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 28,
                    height: 1,
                    color: ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${treinos.length} ativos',
              style: TextStyle(
                color: primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreinosCommandCard extends StatelessWidget {
  final List<Treino> treinos;
  final bool isDark;
  final Color primary;
  final VoidCallback onCreate;

  const _TreinosCommandCard({
    required this.treinos,
    required this.isDark,
    required this.primary,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primaryDeep = BrandPalette.deep(primary);
    final totalExercises = treinos.fold<int>(
      0,
      (sum, treino) => sum + treino.exercicios.length,
    );
    final ready = treinos.where((t) => t.exercicios.isNotEmpty).length;
    final templates = treinos.where((t) => t.isTemplate).length;
    final assembling = treinos.length - ready;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryDeep],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.14 : 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biblioteca sob controle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      assembling == 0
                          ? 'Todos os planos têm exercícios.'
                          : '$assembling plano${assembling == 1 ? '' : 's'} ainda em montagem.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: onCreate,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text(
                  'Novo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CommandMetric(
                  label: 'prontos',
                  value: '$ready',
                  textColor: ink,
                  muteColor: mute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CommandMetric(
                  label: 'exercícios',
                  value: '$totalExercises',
                  textColor: ink,
                  muteColor: mute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CommandMetric(
                  label: 'templates',
                  value: '$templates',
                  textColor: ink,
                  muteColor: mute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommandMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color muteColor;

  const _CommandMetric({
    required this.label,
    required this.value,
    required this.textColor,
    required this.muteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
        ),
        Text(
          action,
          style: TextStyle(
            color: mute,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onCreate;

  const _EmptyState({
    required this.isDark,
    required this.primary,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 150),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(Icons.fitness_center_rounded, color: primary, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Sua biblioteca começa aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um plano base, adicione exercícios e use como ponto de partida para seus alunos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar treino'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreinoCard extends StatelessWidget {
  final Treino treino;
  final int index;
  final bool isDark;
  final Color primary;

  const _TreinoCard({
    required this.treino,
    required this.index,
    required this.isDark,
    required this.primary,
  });

  IconData get _nivelIcon {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO':
        return Icons.local_fire_department_rounded;
      case 'INTERMEDIARIO':
        return Icons.speed_rounded;
      default:
        return Icons.eco_rounded;
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

  String get _nivelLabel {
    final nivel = treino.nivel?.trim();
    if (nivel == null || nivel.isEmpty) {
      return 'Iniciante';
    }
    return nivel[0].toUpperCase() + nivel.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final hasExercises = treino.exercicios.isNotEmpty;
    final series = treino.exercicios.fold<int>(
      0,
      (sum, item) => sum + item.series,
    );
    final estimatedMinutes =
        hasExercises ? (treino.exercicios.length * 5).clamp(12, 90) : 0;

    return InkWell(
      onTap: () => context.push('/treinos/${treino.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: line),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF16213E).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 12),
                spreadRadius: -18,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    hasExercises
                        ? Icons.fitness_center_rounded
                        : Icons.build_circle_outlined,
                    color: primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              treino.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15.5,
                                color: ink,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          if (treino.isTemplate) ...[
                            const SizedBox(width: 8),
                            _TinyBadge(
                              label: 'base',
                              color: primary,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        treino.objetivo?.trim().isNotEmpty == true
                            ? treino.objetivo!.trim()
                            : hasExercises
                            ? 'Plano pronto para atribuir'
                            : 'Estrutura aguardando exercícios',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mute,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: mute),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PlanPill(
                    icon: Icons.list_alt_rounded,
                    value:
                        '${treino.exercicios.length} exercício${treino.exercicios.length == 1 ? '' : 's'}',
                    isDark: isDark,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanPill(
                    icon: Icons.repeat_rounded,
                    value: hasExercises ? '$series séries' : 'em montagem',
                    isDark: isDark,
                    color: hasExercises ? primary : EagleTokens.warn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanPill(
                    icon: _nivelIcon,
                    value: _nivelLabel,
                    isDark: isDark,
                    color: _nivelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: hasExercises ? 1 : 0.28,
                      backgroundColor:
                          isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                      valueColor: AlwaysStoppedAnimation(
                        hasExercises ? primary : EagleTokens.warn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  hasExercises ? '~${estimatedMinutes}min' : 'finalizar',
                  style: TextStyle(
                    color: hasExercises ? mute : EagleTokens.warn,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;
  final Color color;

  const _PlanPill({
    required this.icon,
    required this.value,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 10.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _TinyBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TreinosErrorState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;

  const _TreinosErrorState({
    required this.isDark,
    required this.primary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: mute),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar',
              style: TextStyle(
                color: ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verifique a conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
