import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import 'fx_icon.dart';
import 'fx_motion.dart';

class FxEmptyAction {
  final String label;
  final VoidCallback onTap;

  /// `true` quando a tela já tem o mesmo P0 no sticky/FAB (§11: 1 primário).
  final bool secondary;

  const FxEmptyAction({
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  Widget build() =>
      secondary
          ? FxLiquidSecondaryButton(label: label, onPressed: onTap, expand: false)
          : FxLiquidPrimaryButton(label: label, onPressed: onTap);
}

class FxEmptyState extends StatelessWidget {
  const FxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.quiet = false,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final FxEmptyAction? action;

  /// Top-aligned, smaller chrome — evita “buraco” central morto (chat, hubs).
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (quiet) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s3,
            TokensStrip.s4,
            TokensStrip.s2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FxIcon(name: icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: FocuxHubTypography.body(
                        color: colorScheme.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: FocuxHubTypography.bodyMuted(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: TokensStrip.s3),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: action!.build(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
              ),
              child: Center(
                child: FxIcon(name: icon, size: 28, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!.build(),
            ],
          ],
        ),
      ),
    );
  }
}
