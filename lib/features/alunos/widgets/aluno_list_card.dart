import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/alunos_layout.dart';
import '../constants/alunos_list_filters.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_followup_store.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/alunos_list_sparkline_logic.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/alunos_list_utils.dart';
import 'aluno_avatar.dart';
import 'aluno_list_outreach_actions.dart';

/// Badge de status quiet — fill soft, sem borda (paridade Home).
class AlunoStatusPill extends StatelessWidget {
  const AlunoStatusPill({
    super.key,
    required this.label,
    required this.fill,
    required this.foreground,
    this.compact = false,
  });

  final String label;
  final Color fill;
  final Color foreground;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FocuxHubTypography.chip(foreground).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          height: 1.1,
        ),
      ),
    );
  }
}

class AlunoListCard extends ConsumerWidget {
  final Aluno aluno;
  final bool modoSelecao;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;
  final AlunoFiltro activeFiltro;
  final bool triageContextActive;
  final int diasSemTreinoLimite;
  final bool compact;

  const AlunoListCard({
    super.key,
    required this.aluno,
    this.modoSelecao = false,
    this.isSelected = false,
    this.onToggle,
    this.onLongPress,
    this.activeFiltro = AlunoFiltro.todos,
    this.triageContextActive = false,
    this.diasSemTreinoLimite = AlunoFollowUpStore.diasSemTreinoLimite,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final secondaryInk = alunoListSecondaryInk(isDark);
    final cardPadding =
        compact ? AlunosLayout.cardPaddingCompact : AlunosLayout.cardPadding;
    final avatarGap =
        compact
            ? AlunosLayout.cardAvatarGapCompact
            : AlunosLayout.cardAvatarGap;

    final displayName = fxTitleCaseName(aluno.nome);
    final objetivo = prettyAlunoObjective(aluno.objetivo);
    final status = alunoListStatusBadge(aluno, isDark);
    final statusText = status.label;
    final avatarColor = alunoAvatarFallbackColor(primary: primary);
    final sparkline = alunosListSparklineMetrics(
      points: const [],
      cachedAderenciaPercent: aluno.aderenciaPercent,
    );
    final aderenciaPercent = sparkline.aderenciaPercent;
    final weeklyCheckins = sparkline.weeklyCheckins;
    final sparkValues = sparkline.sparkValues;
    final aderColor = EagleTokens.aderenciaColor(
      (aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );
    final adherenceLabel = adherenceActivityLabel(
      aluno: aluno,
      weeklyCheckins: weeklyCheckins,
    );
    final opsText = alunoListOpsText(
      adherenceLabel: adherenceLabel,
      triageContextActive: triageContextActive,
      aderenciaPercent: aderenciaPercent,
      filtro: activeFiltro,
    );
    final opsIsDays = adherenceLabel.isNotEmpty;
    final meaningfulPercent = alunoListHasMeaningfulPercent(aderenciaPercent);
    final needsOutreach =
        !modoSelecao && activeFiltro == AlunoFiltro.contatoHoje;
    final showOpsLine = opsText.isNotEmpty;
    final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final hasWhatsapp = whatsappNumber.isNotEmpty;
    final outreach = AlunoListOutreachActions(
      alunoId: aluno.id,
      displayName: displayName,
      whatsappNumber: whatsappNumber,
      hasWhatsapp: hasWhatsapp,
      emRisco: aluno.emRisco,
      primary: primary,
      isDark: isDark,
      mute: mute,
      compact: compact,
    );
    final aderenciaLabel =
        opsText.isNotEmpty
            ? opsText
            : (meaningfulPercent
                ? '$aderenciaPercent%'
                : 'aderência indisponível');

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '$displayName, $statusText, $aderenciaLabel'
          '${adherenceLabel.isEmpty ? '' : ', $adherenceLabel'}',
      child: InkWell(
        onTap:
            modoSelecao
            ? onToggle
            : () {
              // Kick /360/operacao before the route builds (cuts skeleton wait).
              // ignore: unawaited_futures
              ref.read(aluno360OperacaoBundleProvider(aluno.id).future);
              context.push('/alunos/${aluno.id}', extra: aluno);
            },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: cardPadding,
            vertical: compact ? 8 : 10,
          ),
          decoration: fxListCardDecoration(
            context,
            accent: primary,
            radius: FxSettingsLayout.groupRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (modoSelecao) ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        key: ValueKey(isSelected),
                        color:
                            isSelected
                                ? primary
                                : (isDark
                                    ? EagleTokens.darkInkMute
                                    : TokensStrip.textSecondary),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  AlunoAvatar(
                    name: displayName,
                    photoUrl: aluno.fotoUrl,
                    fallbackColor: avatarColor,
                    variant:
                        compact
                            ? AlunoAvatarVariant.strip
                            : AlunoAvatarVariant.list,
                  ),
                  SizedBox(width: avatarGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: FocuxHubTypography.body(color: ink).copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.15,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (shouldShowAlunoListBadge(
                              statusText,
                              activeFiltro,
                              triageContextActive: triageContextActive,
                            )) ...[
                              SizedBox(width: compact ? 6 : 8),
                              AlunoStatusPill(
                                label: statusText,
                                fill: status.fill,
                                foreground: status.foreground,
                                compact: compact,
                              ),
                            ],
                          ],
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$objetivo · ${maskEmailForList(aluno.email)}',
                            style: FocuxHubTypography.bodyMuted(
                              color: secondaryInk,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            objetivo,
                            style: FocuxHubTypography.bodyMuted(
                              color: secondaryInk,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (showOpsLine) ...[
                          SizedBox(height: compact ? 4 : 6),
                          Row(
                            children: [
                              Container(
                                width: compact ? 5 : 6,
                                height: compact ? 5 : 6,
                                decoration: BoxDecoration(
                                  color:
                                      opsIsDays
                                          ? (isDark
                                              ? EagleTokens.warnAccentSoft
                                              : EagleTokens.warnDeep)
                                          : aderColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  opsText,
                                  style:
                                      opsIsDays
                                          ? FocuxHubTypography.bodyMuted(
                                            color:
                                                isDark
                                                    ? EagleTokens.warnAccentSoft
                                                    : EagleTokens.warnDeep,
                                            fontWeight: FontWeight.w600,
                                            height: 1.15,
                                          )
                                          : AppTypography.mono(
                                            fontSize: compact ? 11.5 : 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: aderColor,
                                            height: 1.1,
                                          ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!modoSelecao && needsOutreach)
                    outreach
                  else if (!modoSelecao && (compact || triageContextActive))
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: secondaryInk.withValues(alpha: 0.9),
                      ),
                    )
                  else if (!modoSelecao)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (sparkValues.isNotEmpty)
                          FxSparkline(
                            data: sparkValues,
                            color: aderColor,
                            width: compact ? 48 : 56,
                            height: compact ? 18 : 22,
                            strokeWidth: 1.8,
                          )
                        else
                          const SizedBox(height: 3),
                        const SizedBox(height: 6),
                        ExcludeSemantics(
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
                            color: secondaryInk.withValues(alpha: 0.9),
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
  }
}
