import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

/// Índice A–Z na lateral: tocar ou arrastar salta para a letra.
class ExerciseAlphaRail extends StatelessWidget {
  const ExerciseAlphaRail({
    super.key,
    required this.letras,
    required this.onLetra,
    required this.isDark,
    required this.primary,
  });

  final List<String> letras;
  final ValueChanged<String> onLetra;
  final bool isDark;
  final Color primary;

  void _saltar(double dy, double altura) {
    if (letras.isEmpty || altura <= 0) return;
    final i = (dy / altura * letras.length).floor().clamp(
      0,
      letras.length - 1,
    );
    HapticFeedback.selectionClick();
    onLetra(letras[i]);
  }

  @override
  Widget build(BuildContext context) {
    if (letras.length < 5) return const SizedBox.shrink();
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Semantics(
      container: true,
      label: 'Índice alfabético',
      child: LayoutBuilder(
        builder: (context, c) {
          final altura = c.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (d) => _saltar(d.localPosition.dy, altura),
            onVerticalDragUpdate: (d) => _saltar(d.localPosition.dy, altura),
            onTapDown: (d) => _saltar(d.localPosition.dy, altura),
            child: SizedBox(
              width: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final l in letras)
                    Text(
                      l,
                      style: TextStyle(
                        color: mute,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
