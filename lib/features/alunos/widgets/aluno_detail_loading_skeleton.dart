import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_loading.dart';
import '../constants/aluno_360_layout.dart';
import 'aluno360_composite_header.dart';

class AlunoDetailLoadingSkeleton extends StatelessWidget {
  const AlunoDetailLoadingSkeleton({
    super.key,
    required this.tabController,
    required this.isDark,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.line,
    required this.sheetFill,
  });

  final TabController tabController;
  final bool isDark;
  final Color primary;
  final Color ink;
  final Color mute;
  final Color line;
  final Color sheetFill;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroBodyHeight = Aluno360Layout.heroBodyHeight(context);

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: Aluno360CompositeHeaderDelegate(
            topInset: topInset,
            heroBodyHeight: heroBodyHeight,
            heroChild: AlunoDetailHeroSkeleton(
              isDark: isDark,
              primary: primary,
            ),
            tabController: tabController,
            primary: primary,
            mute: mute,
            line: line,
            displayName: 'Carregando',
            ink: ink,
            isDark: isDark,
            onBack: () => safePopOrGo(context, '/alunos'),
            actionsEnabled: false,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Aluno360Layout.screenPadding,
              Aluno360Layout.tabContentGap,
              Aluno360Layout.screenPadding,
              24,
            ),
            child: Column(
              children: [
                Semantics(
                  label: 'Carregando follow-up',
                  child: FxLoading.sectionShimmer(context, height: 168),
                ),
                const SizedBox(height: Aluno360Layout.sectionGap),
                Semantics(
                  label: 'Carregando status operacional',
                  child: FxLoading.sectionShimmer(context, height: 248),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AlunoDetailHeroSkeleton extends StatelessWidget {
  const AlunoDetailHeroSkeleton({
    super.key,
    required this.isDark,
    required this.primary,
  });

  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final base =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : primary.withValues(alpha: 0.12);
    final highlight =
        isDark
            ? Colors.white.withValues(alpha: 0.22)
            : primary.withValues(alpha: 0.22);

    Widget bone(double w, double h, {double radius = 12}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        key: const ValueKey('aluno360_hero_skeleton'),
        width: double.infinity,
        height: Aluno360Layout.heroBodyHeight(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
          border: Border.all(
            color: primary.withValues(alpha: isDark ? 0.14 : 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            bone(40, 40, radius: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bone(120, 14, radius: 8),
                  const SizedBox(height: 6),
                  bone(double.infinity, 10, radius: 6),
                ],
              ),
            ),
            const SizedBox(width: 8),
            bone(62, 38, radius: 12),
          ],
        ),
      ),
    );
  }
}
