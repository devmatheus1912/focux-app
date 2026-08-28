import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_contact_utils.dart';
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
    final showStatusBadge = alunoHeroShouldShowStatusBadge(
      signal: signal,
      status: status,
    );
    final showRiskBand = aluno.emRisco && signal.label == 'Risco operacional';
    final avatarVariant =
        compactContactPriority
            ? AlunoAvatarVariant.strip
            : AlunoAvatarVariant.profile;

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
            horizontal: 4,
            vertical: compactContactPriority ? 2 : 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AlunoAvatar(
                name: displayName,
                photoUrl: aluno.fotoUrl,
                variant: avatarVariant,
              ),
              SizedBox(height: compactContactPriority ? 6 : 10),
              Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    compactContactPriority
                        ? Aluno360Layout.identityNameStyle(context, ink)
                        : FxSettingsLayout.profileName(context, color: ink),
              ),
              SizedBox(height: compactContactPriority ? 2 : 4),
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
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FxSettingsLayout.subhead(color: mute).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              if (showRiskBand) ...[
                SizedBox(height: compactContactPriority ? 4 : 8),
                if (compactContactPriority)
                  _CompactRiskChip(
                    nivel: formatRiscoNivel(aluno.riscoNivel),
                    isDark: isDark,
                  )
                else
                  _HeroRiskBand(
                    nivel: formatRiscoNivel(aluno.riscoNivel),
                    detail: contextLine,
                    isDark: isDark,
                  ),
              ] else if (showStatusBadge) ...[
                SizedBox(height: compactContactPriority ? 6 : 8),
                _IdentityStatusChip(status: status, isDark: isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactRiskChip extends StatelessWidget {
  const _CompactRiskChip({required this.nivel, required this.isDark});

  final String nivel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (ink, bg) = alunoHeroRiscoMetricBadgeColors(isDark, nivel);
    return Semantics(
      label: 'Risco ${nivel.toLowerCase()}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ink.withValues(alpha: isDark ? 0.42 : 0.32)),
        ),
        child: Text(
          'Risco ${nivel.toLowerCase()}',
          style: Aluno360Layout.badgeMicroStyle(context, ink).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _HeroRiskBand extends StatelessWidget {
  const _HeroRiskBand({
    required this.nivel,
    required this.detail,
    required this.isDark,
  });

  final String nivel;
  final String detail;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (ink, bg) = alunoHeroRiscoMetricBadgeColors(isDark, nivel);
    final mute = fxScreenMute(context);

    return Semantics(
      label: 'Risco ${nivel.toLowerCase()}${detail.isEmpty ? '' : ', $detail'}',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ink.withValues(alpha: isDark ? 0.42 : 0.32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 17, color: ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Risco ${nivel.toLowerCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Aluno360Layout.badgeMicroStyle(context, ink).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (detail.isNotEmpty) ...[
              Text(
                ' · ',
                style: Aluno360Layout.metaStyle(context).copyWith(color: mute),
              ),
              Flexible(
                flex: 2,
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Aluno360Layout.metaStyle(context).copyWith(
                    color: mute,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
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
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        Container(
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
              Text(
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
            ],
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
              style: Aluno360Layout.ctaLabelStyle(
                context,
                primary,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityStatusChip extends StatelessWidget {
  const _IdentityStatusChip({required this.status, required this.isDark});

  final AlunoHeroStatusVisual status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background.withValues(alpha: isDark ? 0.35 : 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.foreground.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: Aluno360Layout.badgeMicroStyle(context, status.foreground),
      ),
    );
  }
}
