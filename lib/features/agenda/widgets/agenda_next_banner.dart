import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_schedule.dart';

class AgendaNextBanner extends StatelessWidget {
  const AgendaNextBanner({
    super.key,
    required this.agendamento,
    required this.onTap,
    this.photoUrl,
  });

  final Agendamento agendamento;
  final VoidCallback onTap;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final accent = BrandPalette.sectionAccent(primary, dark: chrome.isDark);
    final title = agendaEventTitle(
      alunoNome: agendamento.alunoNome,
      titulo: agendamento.titulo,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Semantics(
        button: true,
        label:
            'Próximo atendimento ${agendaHm(agendamento.inicio)}, $title. Abrir',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            child: Ink(
              decoration: fxStripCardDecoration(
                context,
                accent: primary,
                radius: TokensStrip.rCard,
                glowStrength: 0.08,
                emphasize: true,
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: chrome.isDark ? 0.24 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FxIcon(name: 'calendar', size: 17, color: accent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo · ${agendaHm(agendamento.inicio)}',
                          style: FocuxHubTypography.bodyMuted(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ).copyWith(fontSize: 11.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dashboardCardTitleStyle(chrome.ink),
                        ),
                      ],
                    ),
                  ),
                  AlunoAvatar(
                    name: title,
                    photoUrl: photoUrl,
                    variant: AlunoAvatarVariant.strip,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AgendaGapTile extends StatelessWidget {
  const AgendaGapTile({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: '$label. Encaixar horário',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(
                color: primary.withValues(alpha: chrome.isDark ? 0.22 : 0.14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Encaixar',
                  style: FocuxHubTypography.bodyMuted(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
