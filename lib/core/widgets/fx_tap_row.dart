import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Linha tocável com forma: borda fina, seta no fim e estado pressionado.
/// A variante `vazio` usa borda pontilhada e "+" para "Adicionar".
class FxTapRow extends StatelessWidget {
  const FxTapRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.vazio = false,
    this.semanticsLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Substitui a seta (um selo, por exemplo).
  final Widget? trailing;
  final bool vazio;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  static const double alturaMin = 56;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final fim =
        trailing ??
        Icon(
          vazio ? Icons.add_rounded : Icons.chevron_right_rounded,
          color: chrome.mute,
        );
    final titulo = FocuxHubTypography.cardTitle(
      color: vazio ? chrome.mute : chrome.ink,
    );

    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? (subtitle == null ? title : '$title, $subtitle'),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: CustomPaint(
            foregroundPainter: vazio ? _Pontilhado(chrome.lineStrong) : null,
            child: Ink(
              decoration: BoxDecoration(
                color: vazio ? Colors.transparent : chrome.cardFill,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                border: vazio ? null : Border.all(color: chrome.lineStrong),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TokensStrip.s3,
                vertical: TokensStrip.s2,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: alturaMin - 16),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: TokensStrip.s3),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: titulo),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: FocuxHubTypography.cardSubtitle(
                                color: chrome.mute,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: TokensStrip.s2),
                    fim,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pontilhado extends CustomPainter {
  _Pontilhado(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final caminho = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(TokensStrip.rCard),
        ),
      );
    final pincel = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final PathMetric trecho in caminho.computeMetrics()) {
      for (double d = 0; d < trecho.length; d += 8) {
        canvas.drawPath(trecho.extractPath(d, d + 4), pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_Pontilhado antigo) => antigo.cor != cor;
}
