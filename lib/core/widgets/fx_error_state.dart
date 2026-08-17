import 'package:flutter/material.dart';

import '../brand/focux_microcopy.dart';
import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';

/// Canonical error + retry — Home 10/10 parity for every hub/satellite screen.
class FxErrorState extends StatelessWidget {
  final bool chromeOnDark;
  final Color primary;
  final String message;
  final VoidCallback onRetry;
  final String? title;
  final IconData icon;

  const FxErrorState({
    super.key,
    required this.chromeOnDark,
    required this.primary,
    required this.message,
    required this.onRetry,
    this.title,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final ink = chromeOnDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute =
        chromeOnDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              label: title ?? FocuxMicrocopy.algoSaiuDoAr,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(
                    alpha: chromeOnDark ? 0.18 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: EagleTokens.bad, size: 26),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title ?? FocuxMicrocopy.algoSaiuDoAr,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.pageTitle(context, color: ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(FocuxMicrocopy.tentarNovamente),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(48, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
