import 'package:flutter/material.dart';

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

  /// Inline section loading bar — matches dashboard pulse / aluno 360 cards.
  static Widget sectionBar(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return LinearProgressIndicator(
      minHeight: 2,
      color: primary,
      backgroundColor: primary.withValues(alpha: 0.12),
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
