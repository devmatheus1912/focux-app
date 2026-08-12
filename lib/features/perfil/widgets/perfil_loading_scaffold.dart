import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Skeleton de carregamento do hub Perfil.
class PerfilLoadingScaffold extends StatelessWidget {
  const PerfilLoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? EagleTokens.darkCard : TokensStrip.cardBg;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final primary = theme.colorScheme.primary;

    return FxShellScaffold(
      useMesh: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          children: [
            Container(
              height: 286,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: [primary, BrandPalette.deep(primary)],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final height in [132.0, 178.0, 228.0])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
