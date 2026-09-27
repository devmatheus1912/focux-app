import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';

/// Loading da Home do aluno: só cabeçalho e foco do dia, os blocos que sempre
/// existem. Semana e evolução dependem do histórico e entram abaixo, sem pulo.
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
              const SkeletonLoader(width: 160, height: 24),
              const SizedBox(
                height: 48,
                child: Row(
                  children: [
                    SkeletonLoader(width: 24, height: 24, borderRadius: 12),
                    SizedBox(width: TokensStrip.s2),
                    SkeletonLoader(width: 180, height: 14),
                  ],
                ),
              ),
              const SizedBox(height: TokensStrip.s2),
              const SkeletonLoader(height: 132, borderRadius: TokensStrip.rCard),
            ],
          ),
        ),
      ),
    );
  }
}
