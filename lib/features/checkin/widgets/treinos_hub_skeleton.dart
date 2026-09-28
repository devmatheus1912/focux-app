import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';

/// Loading da aba Treinos: destaque + três linhas do plano.
class TreinosHubSkeleton extends StatelessWidget {
  const TreinosHubSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: S.of(context).treinosHubCarregando,
      excludeSemantics: true,
      child: const FxContentWidthLimiter(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonLoader(height: 176, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s4),
              SkeletonLoader(width: 120, height: 16),
              SizedBox(height: TokensStrip.s2),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
            ],
          ),
        ),
      ),
    );
  }
}
