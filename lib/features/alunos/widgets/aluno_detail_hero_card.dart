import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../dashboard/widgets/dashboard_hero_widgets.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/aluno_hero_signal.dart';
import 'aluno_avatar.dart';

class AlunoDetailHeroCard extends StatelessWidget {
  const AlunoDetailHeroCard({
    super.key,
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onChat,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final displayName = fxTitleCaseName(aluno.nome);
    final objective = prettyAlunoObjective(aluno.objetivo);
    final status = alunoHeroStatusVisual(aluno);
    final signal = alunoHeroPrimarySignal(aluno);
    final caption = alunoHeroCaption(aluno, signal);

    return Semantics(
      container: true,
      label:
          '$displayName, objetivo $objective, ${status.label}, '
          '${signal.label} ${signal.value}${signal.suffix ?? ''}',
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: _HeroShell(
          isDark: isDark,
          primary: primary,
          photoUrl: aluno.fotoUrl,
          displayName: displayName,
          objective: objective,
          status: status,
          signal: signal,
          caption: caption,
          onChat: onChat,
        ),
      ),
    );
  }
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({
    required this.isDark,
    required this.primary,
    required this.photoUrl,
    required this.displayName,
    required this.objective,
    required this.status,
    required this.signal,
    required this.caption,
    required this.onChat,
  });

  final bool isDark;
  final Color primary;
  final String? photoUrl;
  final String displayName;
  final String objective;
  final AlunoHeroStatusVisual status;
  final AlunoHeroPrimarySignal signal;
  final String caption;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final heroDeep = BrandPalette.deep(primary);

    return Container(
        key: const ValueKey('aluno360_hero_card'),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors:
                isDark
                    ? const [Color(0xFF128989), Color(0xFF0A2E2E)]
                    : [primary, heroDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            ...TokensStrip.coloredDepthGlow(
              primary,
              strength: isDark ? 0.28 : 0.34,
            ),
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.22 : 0.16),
              blurRadius: isDark ? 32 : 26,
              offset: const Offset(0, 14),
              spreadRadius: isDark ? -12 : -16,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          foregroundPainter: DashboardHeroGridPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AlunoAvatar(
                      name: displayName,
                      photoUrl: photoUrl,
                      variant: AlunoAvatarVariant.hero,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _HeroStatusPill(
                                label: status.label,
                                background: status.background,
                                foreground: status.foreground,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center_rounded,
                                  size: 11,
                                  color: dashboardHeroLabelOnTeal(),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    objective,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: dashboardHeroCaptionOnTeal(),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            signal.label,
                            style: TextStyle(
                              color: dashboardHeroLabelOnTeal(),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dashboardHeroCaptionOnTeal(),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          signal.value,
                          style: AppTypography.mono(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                        if (signal.suffix != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 5),
                            child: Text(
                              signal.suffix!,
                              style: TextStyle(
                                color: dashboardHeroLabelOnTeal(),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onChat,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                      ),
                      label: const Text('Chat'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rButton,
                          ),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
