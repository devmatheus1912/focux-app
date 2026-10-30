import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/aluno360_hero_risk_style.dart';
import '../utils/aluno_hero_signal.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno360_resumo_agora.dart';
import 'aluno_avatar.dart';
import '../../../core/widgets/fx_tonal_button.dart';

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
    final status = alunoHeroStatusVisual(aluno, isDark: isDark);
    final signal = alunoHeroPrimarySignal(aluno);
    final caption = alunoHeroCaption(aluno, signal);
    final contextLine = alunoHeroContextLine(signal, caption);
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final showRiskNotice =
        aluno.emRisco && signal.label == riscoOperacionalLabel;
    // O aviso de risco abaixo já carrega a frase ("Priorize contato hoje"):
    // o subtítulo não a repete.
    final subtitle = alunoHeroIdentitySubtitle(
      compactContactPriority: compactContactPriority,
      objectiveDefined: objectiveDefined,
      objective: objective,
      contextLine: showRiskNotice ? '' : contextLine,
    );
    final showStatusBadge = alunoHeroShouldShowStatusBadge(
      signal: signal,
      status: status,
    );
    final nivel = formatRiscoNivel(aluno.riscoNivel);

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
            vertical: compactContactPriority ? 4 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AlunoAvatar(
                name: displayName,
                photoUrl: aluno.fotoUrl,
                variant: AlunoAvatarVariant.profile,
              ),
              SizedBox(height: compactContactPriority ? 8 : 12),
              Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FxSettingsLayout.profileName(context, color: ink),
              ),
              SizedBox(height: compactContactPriority ? 3 : 5),
              if (!objectiveDefined && onDefineObjective != null)
                _IdentityObjectiveRow(
                  status: showStatusBadge && !showRiskNotice
                      ? _IdentityStatusChip(status: status, isDark: isDark)
                      : null,
                  onDefineObjective: onDefineObjective!,
                )
              else if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: compactContactPriority ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: FxSettingsLayout.subhead(color: mute).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              if (showRiskNotice) ...[
                SizedBox(height: compactContactPriority ? 6 : 10),
                _HeroRiskNotice(
                  nivel: nivel,
                  detail: compactContactPriority
                      ? (motivoDeContato(S.of(context), aluno) ?? '')
                      : contextLine,
                  isDark: isDark,
                  compact: compactContactPriority,
                ),
              ] else if (showStatusBadge && (objectiveDefined || onDefineObjective == null)) ...[
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

class _HeroRiskNotice extends StatelessWidget {
  const _HeroRiskNotice({
    required this.nivel,
    required this.detail,
    required this.isDark,
    required this.compact,
  });

  final String nivel;
  final String detail;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Aluno360HeroRiskStyle.resolve(
      context,
      nivel: nivel,
      isDark: isDark,
    );
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);
    final label = 'Risco ${nivel.toLowerCase()}';

    return Semantics(
      label: '$label${detail.isEmpty ? '' : ', $detail'}',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: style.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: style.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Aluno360Layout.metaStyle(context).copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11.5 : 12,
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
                    fontSize: compact ? 11 : 12,
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

/// Sem objetivo: status e o botão na mesma linha.
class _IdentityObjectiveRow extends StatelessWidget {
  const _IdentityObjectiveRow({
    required this.status,
    required this.onDefineObjective,
  });

  final Widget? status;
  final VoidCallback onDefineObjective;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s1,
      children: [
        if (status != null) status!,
        FxTonalButton(
          label: 'Definir objetivo',
          icon: Icons.flag_outlined,
          compact: true,
          onPressed: onDefineObjective,
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
        color:
            isDark ? status.background.withValues(alpha: 0.35) : status.background,
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
