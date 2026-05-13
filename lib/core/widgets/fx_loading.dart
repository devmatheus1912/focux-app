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
