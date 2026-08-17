import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Skeleton de carregamento do hub Perfil.
class PerfilLoadingScaffold extends StatelessWidget {
  const PerfilLoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      useMesh: true,
      body: ListView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: [
          FxLoading.sectionShimmer(context, height: 220),
          const SizedBox(height: 14),
          FxLoading.sectionShimmer(context, height: 132, showHeader: false),
          const SizedBox(height: 12),
          FxLoading.sectionShimmer(context, height: 178),
          const SizedBox(height: 12),
          FxLoading.sectionShimmer(context, height: 160),
        ],
      ),
    );
  }
}
