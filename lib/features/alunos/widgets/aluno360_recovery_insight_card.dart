import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../constants/aluno_360_layout.dart';
import '../../health/data/health_repository.dart';
import '../../health/widgets/recovery_score_ring.dart';

class Aluno360RecoveryInsightCard extends StatefulWidget {
  const Aluno360RecoveryInsightCard({
    super.key,
    required this.recoveryAsync,
    required this.isDark,
    required this.primary,
  });

  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final bool isDark;
  final Color primary;

  @override
  State<Aluno360RecoveryInsightCard> createState() =>
      _Aluno360RecoveryInsightCardState();
}

class _Aluno360RecoveryInsightCardState
    extends State<Aluno360RecoveryInsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(widget.isDark);
    return widget.recoveryAsync.when(
      loading: () => const SizedBox.shrink(),
      error:
          (_, __) => Semantics(
            label: 'Wearable indisponível',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: chrome.panel(radius: TokensStrip.rCard),
              child: Row(
                children: [
                  Icon(Icons.watch_off_outlined, color: EagleTokens.warn, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wearable indisponível',
                      style: Aluno360Layout.panelTitleStyle(
                        context,
                        chrome.mute,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      data: (snapshot) {
        if (snapshot == null) {
          return Semantics(
            button: true,
            label:
                _expanded
                    ? 'Recolher wearable não conectado'
                    : 'Wearable não conectado — toque para expandir',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: chrome.panel(radius: TokensStrip.rCard),
                  child: Row(
                    children: [
                      Icon(
                        Icons.watch_outlined,
                        color: widget.primary.withValues(alpha: 0.75),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _expanded
                              ? 'Aluno ainda não conectou Apple Health ou Google Fit. Peça para conectar no app se fizer sentido.'
                              : 'Wearable · não conectado',
                          style: Aluno360Layout.captionStyle(context).copyWith(
                            color: chrome.mute,
                            height: 1.35,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: chrome.mute,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return Semantics(
          label: 'Prontidão wearable ${snapshot.recoveryLabel}',
          child: Container(
            padding: const EdgeInsets.all(TokensStrip.s4),
            decoration: chrome.panel(
              radius: TokensStrip.rCard,
              accent: widget.primary,
            ),
            child: Row(
              children: [
                RecoveryScoreRing(
                  score: snapshot.recoveryScore,
                  color: widget.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prontidão wearable',
                        style: Aluno360Layout.captionStyle(context).copyWith(
                          color: chrome.mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        snapshot.recoveryLabel,
                        style: Aluno360Layout.sectionTitleStyle(
                          context,
                          chrome.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.recoveryHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Aluno360Layout.captionStyle(context).copyWith(
                          color: chrome.mute,
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
    );
  }
}
