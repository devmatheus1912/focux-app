import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';

/// Skeleton de carregamento da lista de alunos — paridade Perfil/Home.
class AlunosLoadingScaffold extends StatelessWidget {
  const AlunosLoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s3,
          TokensStrip.s4,
          0,
        ),
        children: [
          FxLoading.sectionShimmer(context, height: 52, showHeader: false),
          const SizedBox(height: 10),
          FxLoading.sectionShimmer(context, height: 44, showHeader: false),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: FxLoading.sectionShimmer(
                    context,
                    height: 36,
                    showHeader: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FxLoading.sectionShimmer(
                    context,
                    height: 36,
                    showHeader: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FxLoading.sectionShimmer(
                    context,
                    height: 36,
                    showHeader: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 5; i++) ...[
            FxLoading.sectionShimmer(context, height: 88),
            if (i < 4) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
