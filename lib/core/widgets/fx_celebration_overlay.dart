import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'fx_confetti_burst.dart';
import 'fx_rive_player.dart';
import '../animations/fx_rive_assets.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/focux_typography.dart';

class FxCelebrationOverlay {
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.emoji_events_outlined,
    Color? accent,
  }) async {
    HapticFeedback.mediumImpact();
    final color = accent ?? Theme.of(context).colorScheme.primary;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebracao',
      barrierColor: Colors.black.withValues(alpha: 0.68),
      useRootNavigator: true,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.68)),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: FxConfettiBurst(color: color),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.28,
                  child: FxRivePlayer(
                    asset: FxRiveAssets.confettiBurst,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Center(
              child: Semantics(
                liveRegion: true,
                label: '$title. ${subtitle ?? ''}',
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: Theme.of(ctx).colorScheme.surface,
                      elevation: 16,
                      shadowColor: Colors.black.withValues(alpha: 0.35),
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        color,
                                        color.withValues(alpha: 0.72),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.35),
                                        blurRadius: 24,
                                        spreadRadius: -4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(icon, color: Colors.white, size: 34),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.96, 0.96),
                                  end: const Offset(1.04, 1.04),
                                  duration: 900.ms,
                                  curve: Curves.easeInOut,
                                ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: FocuxTypography.headline(
                                color: Theme.of(ctx).colorScheme.onSurface,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: FocuxHubTypography.bodyMuted(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                autofocus: true,
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Continuar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
