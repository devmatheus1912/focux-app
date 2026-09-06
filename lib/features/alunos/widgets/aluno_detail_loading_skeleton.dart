import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_loading.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_hero_signal.dart';
import 'aluno_avatar.dart';
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
    this.listPreview,
  });

  final TabController tabController;
  final bool isDark;
  final Color primary;
  final Color ink;
  final Color mute;
  final Color line;
  final Color sheetFill;
  final Aluno? listPreview;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroBodyHeight = Aluno360Layout.heroBodyHeight(context);
    final preview = listPreview;
    final displayName =
        preview == null ? 'Carregando' : fxTitleCaseName(preview.nome);

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
              listPreview: preview,
            ),
            tabController: tabController,
            primary: primary,
            mute: mute,
            line: line,
            displayName: displayName,
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
    this.listPreview,
  });

  final bool isDark;
  final Color primary;
  final Aluno? listPreview;

  @override
  Widget build(BuildContext context) {
    final preview = listPreview;
    if (preview != null) {
      final displayName = fxTitleCaseName(preview.nome);
      final status = alunoHeroStatusVisual(preview);
      return Container(
        key: const ValueKey('aluno360_hero_skeleton_preview'),
        width: double.infinity,
        height: Aluno360Layout.heroBodyHeight(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AlunoAvatar(
              name: displayName,
              photoUrl: preview.fotoUrl,
              variant: AlunoAvatarVariant.profile,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: status.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              height: 38,
              child: FxLoading.sectionShimmer(context, height: 38),
            ),
          ],
        ),
      );
    }

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
