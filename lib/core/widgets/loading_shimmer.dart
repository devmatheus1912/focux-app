import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/design_tokens.dart';

class ShimmerListLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerListLoading({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? EagleTokens.surfaceDark.withValues(alpha: 0.8)
        : const Color(0xFFE0E0E0);
    final highlightColor = isDark
        ? const Color(0xFF252540)
        : const Color(0xFFF5F5F5);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: isDark ? EagleTokens.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(EagleTokens.radiusCard),
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerCardLoading extends StatelessWidget {
  final double height;

  const ShimmerCardLoading({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? EagleTokens.surfaceDark.withValues(alpha: 0.8)
        : const Color(0xFFE0E0E0);
    final highlightColor = isDark
        ? const Color(0xFF252540)
        : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(EagleTokens.radiusCard),
        ),
      ),
    );
  }
}
