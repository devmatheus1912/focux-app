import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

class DashboardErrorState extends StatelessWidget {
  final bool chromeOnDark;
  final Color primary;
  final String message;
  final VoidCallback onRetry;

  const DashboardErrorState({
    super.key,
    required this.chromeOnDark,
    required this.primary,
    required this.message,
    required this.onRetry,
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(
                  alpha: chromeOnDark ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: EagleTokens.bad,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              FocuxMicrocopy.algoSaiuDoAr,
              style: AppTypography.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
