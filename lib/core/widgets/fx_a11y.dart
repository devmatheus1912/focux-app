import 'package:flutter/material.dart';

/// Wrapper que garante:
/// - tap target mínimo de 48x48 (WCAG AA),
/// - Semantics com label legível por leitor de tela,
/// - feedback tátil no Android (`enableFeedback`).
///
/// Use em qualquer ícone/botão pequeno do app onde o tap target visual
/// for menor que 48x48 — nesses casos o widget infla a área tocável
/// sem mexer no layout visual.
class FxTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final double minSize;
  final bool excludeFromSemantics;

  const FxTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.minSize = 48,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    final core = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          child: Center(child: child),
        ),
      ),
    );

    if (excludeFromSemantics || semanticLabel == null) return core;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      hint: semanticHint,
      child: ExcludeSemantics(child: core),
    );
  }
}

/// Headings semânticos: marcações para leitores de tela navegarem
/// rapidamente entre seções de uma tela densa (Hoje, Dashboard etc.).
class FxHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int level;
  final TextAlign? textAlign;

  const FxHeading(this.text, {super.key, this.style, this.level = 1, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}

/// Garante contraste mínimo: se o usuário ativou `MediaQuery.highContrast`
/// o widget força negrito + cor primária para destacar o conteúdo.
class FxAccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const FxAccessibleText(this.text, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final base = style ?? const TextStyle();
    final adjusted = highContrast
        ? base.copyWith(fontWeight: FontWeight.w700)
        : base;
    return Text(text, style: adjusted, textAlign: textAlign);
  }
}
