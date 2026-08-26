import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';

class DashboardShimmerLoading extends StatelessWidget {
  const DashboardShimmerLoading({super.key, required this.themeDark});

  final bool themeDark;

  @override
  Widget build(BuildContext context) {
    final base = themeDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight =
        themeDark ? EagleTokens.darkCardHi : TokensStrip.borderDefault;

    Widget bone(double w, double h, {double radius = 12}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    final content = SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          TokensStrip.s5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bone(170, 18, radius: 8),
                      const SizedBox(height: 4),
                      bone(110, 10, radius: 6),
                    ],
                  ),
                ),
                bone(36, 36, radius: 18),
                const SizedBox(width: 6),
                bone(40, 40, radius: 20),
                const SizedBox(width: 6),
                bone(36, 36, radius: 18),
              ],
            ),
            const SizedBox(height: 14),
            bone(140, 16),
            const SizedBox(height: 12),
            for (int i = 0; i < 2; i++) ...[
              Padding(
                padding: EdgeInsets.only(bottom: i < 1 ? 10 : 0),
                child: Row(
                  children: [
                    bone(40, 40, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bone(160, 13),
                          const SizedBox(height: 6),
                          bone(100, 10),
                        ],
                      ),
                    ),
                    bone(28, 28, radius: 8),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            bone(120, 12, radius: 8),
            const SizedBox(height: 8),
            for (int i = 0; i < 3; i++) ...[
              Padding(
                padding: EdgeInsets.only(bottom: i < 2 ? 2 : 0),
                child: Row(
                  children: [
                    bone(FxSettingsLayout.iconSize, FxSettingsLayout.iconSize, radius: 6),
                    const SizedBox(width: FxSettingsLayout.iconGap),
                    Expanded(
                      child: bone(
                        double.infinity,
                        FxSettingsLayout.rowMinHeight,
                        radius: FxSettingsLayout.groupRadius,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            bone(120, 16),
            const SizedBox(height: 14),
            for (int i = 0; i < 4; i++) ...[
              Padding(
                padding: EdgeInsets.only(bottom: i < 3 ? 8 : 0),
                child: Row(
                  children: [
                    bone(36, 36, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bone(140, 12),
                          const SizedBox(height: 5),
                          bone(80, 9),
                        ],
                      ),
                    ),
                    bone(40, 14, radius: 7),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

    if (reduceMotionOf(context)) {
      return content;
    }

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: content,
    );
  }
}
