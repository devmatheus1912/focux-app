import 'dart:math' as math;

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
    this.onDefineObjective,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback? onDefineObjective;

  @override
  Widget build(BuildContext context) {
    final displayName = fxTitleCaseName(aluno.nome);
    final objectiveDefined = alunoObjectiveIsDefined(aluno.objetivo);
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
          objectiveDefined: objectiveDefined,
          onDefineObjective: onDefineObjective,
          status: status,
          signal: signal,
          caption: caption,
        ),
      ),
    );
  }
}

class _HeroShell extends StatefulWidget {
  const _HeroShell({
    required this.isDark,
    required this.primary,
    required this.photoUrl,
    required this.displayName,
    required this.objective,
    required this.objectiveDefined,
    required this.status,
    required this.signal,
    required this.caption,
    this.onDefineObjective,
  });

  final bool isDark;
  final Color primary;
  final String? photoUrl;
  final String displayName;
  final String objective;
  final bool objectiveDefined;
  final VoidCallback? onDefineObjective;
  final AlunoHeroStatusVisual status;
  final AlunoHeroPrimarySignal signal;
  final String caption;

  @override
  State<_HeroShell> createState() => _HeroShellState();
}

class _HeroShellState extends State<_HeroShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradientCtrl;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (TokensStrip.prefersReducedMotion(context)) {
      _gradientCtrl.stop();
    } else {
      _gradientCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroDeep = BrandPalette.deep(widget.primary);
    final reduceMotion = TokensStrip.prefersReducedMotion(context);

    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (context, _) {
        final angle =
            reduceMotion ? 0.0 : _gradientCtrl.value * 2 * math.pi;
        final begin = Alignment(-math.cos(angle), -math.sin(angle));
        final end = Alignment(math.cos(angle), math.sin(angle));

        return Container(
          key: const ValueKey('aluno360_hero_card'),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors:
                  widget.isDark
                      ? const [Color(0xFF128989), Color(0xFF0A2E2E)]
                      : [widget.primary, heroDeep],
              begin: begin,
              end: end,
            ),
            boxShadow: [
              ...TokensStrip.coloredDepthGlow(
                widget.primary,
                strength: widget.isDark ? 0.28 : 0.34,
              ),
              BoxShadow(
                color: widget.primary.withValues(
                  alpha: widget.isDark ? 0.22 : 0.16,
                ),
                blurRadius: widget.isDark ? 24 : 20,
                offset: const Offset(0, 10),
                spreadRadius: widget.isDark ? -10 : -14,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            foregroundPainter: DashboardHeroGridPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 6, 11, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AlunoAvatar(
                        name: widget.displayName,
                        photoUrl: widget.photoUrl,
                        variant: AlunoAvatarVariant.hero,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.35,
                                      height: 1.05,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _HeroStatusPill(
                                  label: widget.status.label,
                                  background: widget.status.background,
                                  foreground: widget.status.foreground,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _HeroObjectiveRow(
                              label: widget.objective,
                              defined: widget.objectiveDefined,
                              onDefineObjective: widget.onDefineObjective,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.signal.label,
                              style: TextStyle(
                                color: dashboardHeroLabelOnTeal(),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              widget.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: dashboardHeroCaptionOnTeal(),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.signal.value,
                            style: AppTypography.mono(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              height: 1,
                            ),
                          ),
                          if (widget.signal.suffix != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Text(
                                widget.signal.suffix!,
                                style: TextStyle(
                                  color: dashboardHeroLabelOnTeal(),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroObjectiveRow extends StatelessWidget {
  const _HeroObjectiveRow({
    required this.label,
    required this.defined,
    this.onDefineObjective,
  });

  final String label;
  final bool defined;
  final VoidCallback? onDefineObjective;

  @override
  Widget build(BuildContext context) {
    if (defined) {
      return Semantics(
        label: 'Objetivo: $label',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
                  label,
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
      );
    }

    return Row(
      children: [
        Flexible(
          child: Semantics(
            label: 'Objetivo pendente de definição',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onDefineObjective != null)
          Semantics(
            button: true,
            label: 'Definir objetivo do aluno',
            child: TextButton(
              onPressed: onDefineObjective,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Definir',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.2,
                ),
              ),
            ),
          ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
