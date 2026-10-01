import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Placeholder com a forma dos cards de exercício enquanto a IA gera.
class IaProgressaoLoadingSkeleton extends StatelessWidget {
  const IaProgressaoLoadingSkeleton({super.key, this.cards = 3});

  final int cards;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Gerando sugestões de progressão com IA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TokensStrip.s4),
          for (var i = 0; i < cards; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s3),
              child: DecoratedBox(
                decoration: fxListCardDecoration(context, accent: primary),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.55,
                        child: FxLoading.sectionShimmer(
                          context,
                          height: 16,
                          showHeader: false,
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s3),
                      Row(
                        children: [
                          Expanded(
                            child: FxLoading.sectionShimmer(
                              context,
                              height: 56,
                              showHeader: false,
                            ),
                          ),
                          const SizedBox(width: TokensStrip.s6),
                          Expanded(
                            child: FxLoading.sectionShimmer(
                              context,
                              height: 56,
                              showHeader: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
