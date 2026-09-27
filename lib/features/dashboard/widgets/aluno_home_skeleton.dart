import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';

/// Loading da Home do aluno no formato do conteúdo: cabeçalho, foco do dia,
/// semana (3 métricas) e evolução.
class AlunoHomeSkeleton extends StatelessWidget {
  const AlunoHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).alunoHomeCarregando,
      excludeSemantics: true,
      child: FxContentWidthLimiter(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLoader(width: 160, height: 22),
              const SizedBox(height: TokensStrip.s2),
              const SkeletonLoader(width: 200, height: 14),
              const SizedBox(height: TokensStrip.s4),
              const SkeletonLoader(height: 132, borderRadius: TokensStrip.rCard),
              const SizedBox(height: TokensStrip.s5),
              const SkeletonLoader(width: 110, height: 16),
              const SizedBox(height: TokensStrip.s2),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: TokensStrip.s2),
                    const Expanded(
                      child: SkeletonLoader(
                        height: 64,
                        borderRadius: TokensStrip.rCard,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: TokensStrip.s5),
              const SkeletonLoader(width: 110, height: 16),
              const SizedBox(height: TokensStrip.s2),
              const SkeletonLoader(height: 160, borderRadius: TokensStrip.rCard),
            ],
          ),
        ),
      ),
    );
  }
}
