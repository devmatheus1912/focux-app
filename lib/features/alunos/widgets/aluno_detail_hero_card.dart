import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../constants/aluno_360_layout.dart';
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
    this.compactContactPriority = false,
    this.onDefineObjective,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final bool compactContactPriority;
  final VoidCallback? onDefineObjective;

  @override
  Widget build(BuildContext context) {
    final displayName = fxTitleCaseName(aluno.nome);
    final objectiveDefined = alunoObjectiveIsDefined(aluno.objetivo);
    final objective = prettyAlunoObjective(aluno.objetivo);
    final status = alunoHeroStatusVisual(aluno);
    final signal = alunoHeroPrimarySignal(aluno);
    final caption = alunoHeroCaption(aluno, signal);
    final contextLine = alunoHeroContextLine(signal, caption);
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final subtitle = alunoHeroIdentitySubtitle(
      compactContactPriority: compactContactPriority,
      objectiveDefined: objectiveDefined,
      objective: objective,
      contextLine: contextLine,
    );
    final subtitleMaxLines = 1;

    return Semantics(
      container: true,
      label:
          '$displayName, objetivo $objective, ${status.label}, '
          '${signal.label} ${signal.value}${signal.suffix ?? ''}',
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: Container(
          key: const ValueKey('aluno360_hero_card'),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compactContactPriority ? 6 : 8,
          ),
          decoration: Aluno360Layout.operacaoInsetSectionDecoration(
            context,
            primary: primary,
            isDark: isDark,
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AlunoAvatar(
                        name: displayName,
                        photoUrl: aluno.fotoUrl,
                        variant:
                            compactContactPriority
                                ? AlunoAvatarVariant.strip
                                : AlunoAvatarVariant.hero,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Aluno360Layout.identityNameStyle(
                                      context,
                                      ink,
                                    ),
                                  ),
                                ),
                                if (alunoHeroShouldShowStatusBadge(
                                  signal: signal,
                                  status: status,
                                )) ...[
                                  const SizedBox(width: 6),
                                  _IdentityStatusChip(
                                    status: status,
                                    isDark: isDark,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (!objectiveDefined && onDefineObjective != null)
                              _IdentityObjectiveRow(
                                label: objective,
                                primary: primary,
                                isDark: isDark,
                                mute: mute,
                                onDefineObjective: onDefineObjective!,
                              )
                            else
                              Text(
                                subtitle,
                                maxLines: subtitleMaxLines,
                                overflow: TextOverflow.ellipsis,
                                style: Aluno360Layout.captionStyle(context)
                                    .copyWith(
                                      color: mute,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _IdentityMetricChip(
                        signal: signal,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IdentityObjectiveRow extends StatelessWidget {
  const _IdentityObjectiveRow({
    required this.label,
    required this.primary,
    required this.isDark,
    required this.mute,
    required this.onDefineObjective,
  });

  final String label;
  final Color primary;
  final bool isDark;
  final Color mute;
  final VoidCallback onDefineObjective;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.24 : 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_outlined, size: 11, color: mute),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mute,
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
        Semantics(
          button: true,
          label: 'Definir objetivo do aluno',
          child: TextButton(
            onPressed: onDefineObjective,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: primary,
            ),
            child: const Text(
              'Definir',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityStatusChip extends StatelessWidget {
  const _IdentityStatusChip({
    required this.status,
    required this.isDark,
  });

  final AlunoHeroStatusVisual status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.background.withValues(alpha: isDark ? 0.35 : 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: status.foreground.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.foreground,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IdentityMetricChip extends StatelessWidget {
  const _IdentityMetricChip({
    required this.signal,
    required this.isDark,
    required this.primary,
  });

  final AlunoHeroPrimarySignal signal;
  final bool isDark;
  final Color primary;

  Color _accentColor() {
    return switch (signal.label) {
      'Risco operacional' => EagleTokens.bad,
      'Aderência semanal' => EagleTokens.aderenciaColor(
        double.tryParse(signal.value) ?? 0,
        isDark: isDark,
      ),
      'Sem treino' => EagleTokens.warn,
      _ => primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final accent = _accentColor();
    final eyebrow = alunoHeroMetricEyebrow(signal);
    final emphasis =
        signal.label == 'Risco operacional' || signal.label == 'Sem treino'
            ? OperationalMetricEmphasis.alert
            : OperationalMetricEmphasis.normal;
    final eyebrowColor =
        emphasis == OperationalMetricEmphasis.alert
            ? (isDark
                ? accent.withValues(alpha: 0.95)
                : Color.lerp(accent, const Color(0xFF7F1D1D), 0.35)!)
            : Color.lerp(ink, accent, 0.35)!;
    final valueColor =
        emphasis == OperationalMetricEmphasis.alert
            ? (isDark
                ? ink
                : Color.lerp(accent, const Color(0xFF450A0A), 0.55)!)
            : ink;

    return Semantics(
      label: '${eyebrow ?? signal.label} ${signal.value}${signal.suffix ?? ''}',
      child: Container(
      constraints: const BoxConstraints(minWidth: 62),
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: operationalMetricDecoration(
        accent: accent,
        isDark: isDark,
        emphasis: emphasis,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null)
            Text(
              eyebrow.toUpperCase(),
              style: AppTypography.inter(
                color: eyebrowColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
                height: 1,
              ),
            ),
          if (eyebrow != null) const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                signal.value,
                style: AppTypography.condensed(
                  color: valueColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1,
                ),
              ),
              if (signal.suffix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 1),
                  child: Text(
                    signal.suffix!,
                    style: AppTypography.inter(
                      color: fxScreenMute(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
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
