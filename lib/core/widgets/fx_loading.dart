import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/design_tokens.dart';
import '../theme/tokens_strip.dart';
import '../utils/motion_preferences.dart';

/// Premium loading indicator — sized, subtle, and consistent.
/// Drop-in replacement for the banned `Center(child: CircularProgressIndicator())`.
class FxLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final double? value;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;

  const FxLoading({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.5,
    this.color,
    this.value,
    this.backgroundColor,
    this.valueColor,
  });

  /// Card-shaped skeleton aligned with ShellChrome / dashboard shimmer.
  static Widget sectionShimmer(
    BuildContext context, {
    double height = 128,
    bool showHeader = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight =
        isDark ? EagleTokens.darkCardHi : TokensStrip.borderDefault;

    Widget bone(double w, double h, {double radius = 12}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    final content = SizedBox(
      height: height,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                bone(38, 38, radius: 13),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bone(140, 13, radius: 8),
                      const SizedBox(height: 6),
                      bone(96, 10, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Expanded(child: bone(double.infinity, double.infinity, radius: 16)),
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: strokeWidth,
          color: color,
          backgroundColor: backgroundColor,
          valueColor: valueColor,
        ),
      ),
    );
  }
}
