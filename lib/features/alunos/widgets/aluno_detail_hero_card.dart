import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/aluno_hero_signal.dart';
import '../utils/alunos_list_utils.dart';
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, nameConstraints) {
                                      final showStatusBadge =
                                          alunoHeroShouldShowStatusBadge(
                                            signal: signal,
                                            status: status,
                                          );
                                      final stackStatusBadge =
                                          showStatusBadge &&
                                          nameConstraints.maxWidth < 140;
                                      final nameStyle =
                                          Aluno360Layout.identityNameStyle(
                                            context,
                                            ink,
                                          );
                                      if (stackStatusBadge) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: nameStyle,
                                            ),
                                            const SizedBox(height: 2),
                                            _IdentityStatusChip(
                                              status: status,
                                              isDark: isDark,
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: nameStyle,
                                            ),
                                          ),
                                          if (showStatusBadge) ...[
                                            const SizedBox(width: 4),
                                            _IdentityStatusChip(
                                              status: status,
                                              isDark: isDark,
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(
                                    height: compactContactPriority ? 2 : 4,
                                  ),
                                  if (!objectiveDefined &&
                                      onDefineObjective != null)
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
                                      style:
                                          Aluno360Layout.captionStyle(context)
                                              .copyWith(
                                                color: mute,
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _IdentityMetricChip(
                  signal: signal,
                  isDark: isDark,
                  primary: primary,
                  compact: compactContactPriority,
                ),
              ),
            ],
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
                      fontSize: 12,
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
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.padded,
              foregroundColor: primary,
            ),
            child: Text(
              'Definir',
              style: Aluno360Layout.ctaLabelStyle(context, primary).copyWith(
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
        style: Aluno360Layout.badgeMicroStyle(context, status.foreground),
      ),
    );
  }
}

class _IdentityMetricChip extends StatelessWidget {
  const _IdentityMetricChip({
    required this.signal,
    required this.isDark,
    required this.primary,
    this.compact = false,
  });

  final AlunoHeroPrimarySignal signal;
  final bool isDark;
  final Color primary;
  final bool compact;

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
    if (signal.label == 'Risco operacional') {
      return _HeroRiscoMetricBadge(
        nivel: signal.value,
        isDark: isDark,
        compact: compact,
      );
    }

    final ink = fxScreenInk(context);
    final accent = _accentColor();
    final eyebrow = alunoHeroMetricEyebrow(signal);
    final emphasis =
        signal.label == 'Sem treino'
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

    final semanticsLabel =
        '${eyebrow ?? signal.label} ${signal.value}${signal.suffix ?? ''}';

    if (compact) {
      return Semantics(
        label: semanticsLabel,
        child: Container(
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: operationalMetricDecoration(
            accent: accent,
            isDark: isDark,
            emphasis: emphasis,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow,
                  style: AppTypography.inter(
                    color: eyebrowColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                signal.value,
                style: AppTypography.condensed(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.05,
                ),
              ),
              if (signal.suffix != null)
                Text(
                  signal.suffix!,
                  style: AppTypography.inter(
                    color: fxScreenMute(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: Container(
        constraints: const BoxConstraints(minWidth: 62),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                eyebrow,
                style: Aluno360Layout.eyebrowLabelStyle(
                  context,
                  eyebrowColor,
                ),
              ),
            if (eyebrow != null) const SizedBox(height: 3),
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                if (signal.suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Text(
                      signal.suffix!,
                      style: AppTypography.inter(
                        color: fxScreenMute(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
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

/// Badge de risco no hero — contraste AA, cabe no slot compacto (52px).
class _HeroRiscoMetricBadge extends StatelessWidget {
  const _HeroRiscoMetricBadge({
    required this.nivel,
    required this.isDark,
    this.compact = false,
  });

  final String nivel;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (ink, bg) = alunoHeroRiscoMetricBadgeColors(isDark, nivel);
    final valueInk =
        isDark
            ? const Color(0xFFFFF4E8)
            : Color.lerp(ink, const Color(0xFF1A1208), 0.22)!;
    final contentPadding =
        compact
            ? const EdgeInsets.fromLTRB(7, 4, 9, 4)
            : const EdgeInsets.fromLTRB(8, 6, 10, 6);
    final accentHeight = compact ? 22.0 : 30.0;

    return Semantics(
      label: 'Risco ${nivel.toLowerCase()}',
      child: Container(
        constraints: BoxConstraints(minWidth: compact ? 64 : 68),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(compact ? 9 : 10),
          border: Border.all(
            color: ink.withValues(alpha: isDark ? 0.42 : 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 6,
                top: contentPadding.top,
                bottom: contentPadding.bottom,
              ),
              child: Container(
                width: 3,
                height: accentHeight,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: contentPadding.copyWith(left: 5),
              child:
                  compact
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Risco',
                            style: AppTypography.inter(
                              color: ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            nivel,
                            style: AppTypography.condensed(
                              color: valueInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.15,
                              height: 1.05,
                            ),
                          ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Risco',
                            style: AppTypography.inter(
                              color: ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nivel,
                            style: AppTypography.condensed(
                              color: valueInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
