import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';
import 'fx_shell_scaffold.dart';

/// Card padrão do design system — superfície "strip" da Home.
///
/// Encapsula [fxStripCardDecoration]: fill branco/glass, borda teal e
/// depth glow. Use em QUALQUER card de conteúdo de hub/satélite no lugar
/// de `BoxDecoration` ad-hoc, `Card` do Material ou glass reinventado.
///
/// Quando usar:
/// - Card comum de seção → `FxStripCard(child: ...)`
/// - Lead/P0 (destaque do fold) → `FxStripCard(emphasize: true, ...)`
/// - Card silencioso (rail secundário) → `glowStrength: 0.03–0.08`
///
/// Quando NÃO usar:
/// - Linhas de lista com ink splash → [fxListTileCardShell]
/// - Bottom sheets → `showFxHomeSheet` / `FxHomeSheetSurface`
class FxStripCard extends StatelessWidget {
  const FxStripCard({
    super.key,
    required this.child,
    this.accent,
    this.radius = TokensStrip.rCard,
    this.glowStrength = 0.44,
    this.emphasize = false,
    this.padding = const EdgeInsets.all(TokensStrip.s4),
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;

  /// Accent da marca (white-label). Default: `colorScheme.primary`.
  final Color? accent;

  /// Raio da superfície. Home usa [TokensStrip.rCard] (12); hero 24.
  final double radius;

  /// Intensidade do depth glow (light). Home: 0.03 quiet · 0.44 default ·
  /// emphasize sobe sozinho para 0.62.
  final double glowStrength;

  /// Lead P0 — borda mais forte + glow maior (padrão Home/sheet).
  final bool emphasize;

  final EdgeInsetsGeometry padding;

  /// Quando presente, o card inteiro vira alvo de toque (48dp mínimo é
  /// responsabilidade do conteúdo/padding).
  final VoidCallback? onTap;

  /// Rótulo para leitores de tela quando o card é interativo.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    Widget surface = DecoratedBox(
      decoration: fxStripCardDecoration(
        context,
        accent: accent,
        radius: radius,
        glowStrength: glowStrength,
        emphasize: emphasize,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return surface;

    surface = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: surface,
      ),
    );
    if (semanticsLabel == null) return surface;
    return Semantics(button: true, label: semanticsLabel, child: surface);
  }
}
