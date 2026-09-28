import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';
import '../utils/aluno_home_texts.dart';
import '../utils/aluno_today_action.dart';
import 'aluno_home_insight_line.dart';

/// Card de foco: a única superfície com `emphasize` na Home.
class AlunoTodayFocusCard extends StatelessWidget {
  final AlunoTodayAction action;
  final DateTime hoje;
  final bool isDark;
  final VoidCallback onAction;
  final AlunoHomeInsight? insight;

  /// Próximo horário de hoje ou amanhã (`alunoHorarioNoFoco`).
  final DateTime? horario;
  final bool prontidaoBaixa;

  const AlunoTodayFocusCard({
    super.key,
    required this.action,
    required this.hoje,
    required this.isDark,
    required this.onAction,
    this.insight,
    this.horario,
    this.prontidaoBaixa = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final texto = alunoTodayTexto(
      s,
      action,
      hoje: hoje,
      prontidaoBaixa: prontidaoBaixa,
    );
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;

    return FxStripCard(
      emphasize: true,
      glowStrength: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto.eyebrow,
            style: FocuxHubTypography.eyebrow(context, color: mute),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            texto.titulo,
            style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            texto.descricao,
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
          if (texto.prazo case final prazo?) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(prazo, style: FocuxHubTypography.bodyMuted(color: mute)),
          ],
          if (horario case final h?) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              alunoHorarioFocoTexto(s, h, hoje: hoje),
              style: FocuxHubTypography.bodyMuted(
                color: chrome.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (insight case final insight?) ...[
            const SizedBox(height: TokensStrip.s3),
            AlunoHomeInsightLine(insight: insight, onPrimary: mute),
          ],
          const SizedBox(height: TokensStrip.s3),
          FxActionChip(
            label: texto.cta,
            accent: primary,
            isDark: isDark,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
