import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';

/// Texto longo de IA que recolhe em [maxLines]; o link só aparece se transbordar.
class IaExpandableCopy extends StatefulWidget {
  const IaExpandableCopy({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.expandLabel = 'Ler mensagem inteira',
    this.collapseLabel = 'Recolher',
    this.style,
  });

  final String text;
  final int maxLines;
  final String expandLabel;
  final String collapseLabel;
  final TextStyle? style;

  @override
  State<IaExpandableCopy> createState() => _IaExpandableCopyState();
}

class _IaExpandableCopyState extends State<IaExpandableCopy> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: TokensStrip.textSecondary,
        );

    return Semantics(
      label: widget.text,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: style),
            maxLines: widget.maxLines,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final expandable = painter.didExceedMaxLines;
          painter.dispose();
          final collapsed = expandable && !_expanded;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: fxMotionDuration(context),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: Text(
                  widget.text,
                  style: style,
                  maxLines: collapsed ? widget.maxLines : null,
                  overflow: collapsed ? TextOverflow.ellipsis : null,
                ),
              ),
              if (expandable) ...[
                const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: _expanded ? widget.collapseLabel : widget.expandLabel,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _expanded ? widget.collapseLabel : widget.expandLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
