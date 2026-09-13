import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../theme/tokens_strip.dart';

/// Seletor de 1–5 estrelas — S5 depoimento e reviews.
class FxStarRating extends StatelessWidget {
  const FxStarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 40,
    this.enabled = true,
    this.semanticLabel = 'Nota',
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  final bool enabled;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final nota = value.clamp(1, 5);
    return Semantics(
      label: '$semanticLabel $nota de 5',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s1),
              child: IconButton(
                tooltip: '$i estrela${i == 1 ? '' : 's'}',
                onPressed: !enabled || onChanged == null
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onChanged!(i);
                      },
                iconSize: size,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: size + 8,
                  height: size + 8,
                ),
                icon: Icon(
                  i <= nota ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: EagleTokens.goldStar,
                  size: size,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
