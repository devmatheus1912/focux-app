import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Estado de erro do hub Perfil.
class PerfilErrorScaffold extends StatelessWidget {
  const PerfilErrorScaffold({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return FxShellScaffold(
      useMesh: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: EagleTokens.badSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  color: EagleTokens.bad,
                  size: 28,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              Text(
                'Perfil indisponível',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                friendlyError(
                  error,
                  fallback: 'Não foi possível carregar seus dados agora.',
                ),
                textAlign: TextAlign.center,
                style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.35),
              ),
              const SizedBox(height: 18),
              FxLiquidPrimaryButton(
                icon: Icons.refresh_rounded,
                label: 'Tentar novamente',
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
