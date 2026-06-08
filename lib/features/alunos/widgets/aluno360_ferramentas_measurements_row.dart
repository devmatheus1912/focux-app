import 'package:flutter/material.dart';

import '../utils/aluno360_ferramentas_logic.dart';

/// Intrinsic-height row(s) for Ferramentas measurement cards (no aspect-ratio dead space).
class Aluno360FerramentasMeasurementsRow extends StatelessWidget {
  const Aluno360FerramentasMeasurementsRow({
    super.key,
    required this.cards,
  });

  final List<Widget> cards;

  Widget _row(List<Widget> rowCards) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rowCards.length; i++) ...[
            if (i > 0)
              const SizedBox(width: Aluno360FerramentasLogic.measurementRowGap),
            Expanded(child: rowCards[i]),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(cards.length == 4, 'Ferramentas measurements expect exactly 4 cards');

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = Aluno360FerramentasLogic.measurementCrossAxisCount(
          constraints.maxWidth,
        );
        if (crossAxisCount == 4) {
          return _row(cards);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(cards.sublist(0, 2)),
            const SizedBox(height: Aluno360FerramentasLogic.measurementRowGap),
            _row(cards.sublist(2, 4)),
          ],
        );
      },
    );
  }
}
