import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_rive_player.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/health_repository.dart';
import 'recovery_score_ring.dart';

/// Prontidão na Home do aluno, a partir do BFF. Quem decide se o bloco
/// aparece é `alunoProntidaoVisivel`; sem [snapshot], a última prontidão é
/// antiga e o card convida a sincronizar.
class AlunoRecoveryCard extends StatelessWidget {
  const AlunoRecoveryCard({super.key, required this.snapshot});

  final RecoverySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final snap = snapshot;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);

    return Semantics(
      button: true,
      label:
          snap == null
              ? s.alunoProntidaoSincronizar
              : s.alunoProntidaoSemantics(
                snap.recoveryLabel,
                snap.recoveryHint,
              ),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/saude');
          },
          child: Ink(
            decoration: fxListCardDecoration(context, accent: primary),
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Row(
              children: [
                if (snap == null)
                  Icon(Icons.watch_outlined, color: primary)
                else
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      RecoveryScoreRing(
                        score: snap.recoveryScore,
                        color: primary,
                        size: 54,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: FxRiveHeartPulse(size: 22),
                      ),
                    ],
                  ),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child:
                      snap == null
                          ? Text(
                            s.alunoProntidaoSincronizar,
                            style: FocuxHubTypography.bodyMuted(
                              color: chrome.mute,
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.alunoProntidaoTitulo,
                                style: FocuxHubTypography.eyebrow(
                                  context,
                                  color: chrome.mute,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s1),
                              Text(
                                snap.recoveryLabel,
                                style: FocuxHubTypography.cardTitle(
                                  color: chrome.ink,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s1),
                              Text(
                                snap.recoveryHint,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.bodyMuted(
                                  color: chrome.mute,
                                ),
                              ),
                            ],
                          ),
                ),
                Icon(Icons.chevron_right_rounded, color: chrome.mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
