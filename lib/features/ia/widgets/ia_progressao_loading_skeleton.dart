import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Shimmer placeholder while IA progressão is generating.
class IaProgressaoLoadingSkeleton extends StatelessWidget {
  const IaProgressaoLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Gerando sugestões de progressão com IA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TokensStrip.s3),
          const Divider(),
          const SizedBox(height: TokensStrip.s2),
          FxLoading.sectionShimmer(context, height: 72, showHeader: false),
          const SizedBox(height: TokensStrip.s3),
          Container(
            decoration: fxListCardDecoration(context, accent: primary),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: FxLoading.sectionShimmer(
                context,
                height: 148,
                showHeader: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
