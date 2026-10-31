import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/shell_chrome.dart';

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
CardDeMarca _cardDeMarca(BuildContext context, Color? accent) {
  final theme = Theme.of(context);
  return BrandPalette.cardDeMarca(
    accent ?? theme.colorScheme.primary,
    dark: theme.brightness == Brightness.dark,
  );
}

/// Degradê do bloco de identidade.
BoxDecoration fxMarcaDecoration(
  BuildContext context, {
  Color? accent,
  double radius = TokensStrip.rCard,
}) {
  final cor = _cardDeMarca(context, accent);
  return BoxDecoration(
    gradient: cor.degrade,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: cor.fundo.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.30 : 0.22,
        ),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

/// Paleta do texto sobre o bloco: a marca pode ser clara ou escura.
ShellPalette fxPaletaSobreMarca(BuildContext context, {Color? accent}) =>
    _PaletaSobreMarca(_cardDeMarca(context, accent));

class _PaletaSobreMarca extends ShellPalette {
  _PaletaSobreMarca(this.cor)
    : super(cor.sobre.computeLuminance() > 0.5, brand: cor.sobre);

  final CardDeMarca cor;

  @override
  Color get ink => cor.sobre;

  @override
  Color get mute => cor.sobreSuave;

  @override
  Color get line => cor.sobre.withValues(alpha: 0.20);

  @override
  Color get lineStrong => cor.sobre.withValues(alpha: 0.35);
}

/// Tema de quem está sobre o bloco: botões e chips acompanham a [fxPaletaSobreMarca].
ThemeData fxTemaSobreMarca(BuildContext context, {Color? accent}) {
  final base = Theme.of(context);
  final paleta = fxPaletaSobreMarca(context, accent: accent);
  final brilho = paleta.isDark ? Brightness.dark : Brightness.light;
  return base.copyWith(
    brightness: brilho,
    colorScheme: base.colorScheme.copyWith(
      brightness: brilho,
      primary: paleta.brand,
      onPrimary: _cardDeMarca(context, accent).fundo,
    ),
  );
}

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
    this.marca = false,
  });

  /// Bloco de identidade: degradê na cor da marca. Um por tela, no card mais
  /// importante. O texto de dentro usa [fxPaletaSobreMarca].
  final bool marca;

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
      decoration:
          marca
              ? fxMarcaDecoration(context, accent: accent, radius: radius)
              : fxStripCardDecoration(
                context,
                accent: accent,
                radius: radius,
                glowStrength: glowStrength,
                emphasize: emphasize,
              ),
      child:
          marca
              ? Theme(
                data: fxTemaSobreMarca(context, accent: accent),
                child: Padding(padding: padding, child: child),
              )
              : Padding(padding: padding, child: child),
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
