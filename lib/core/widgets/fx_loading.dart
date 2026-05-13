import 'package:flutter/material.dart';

/// Premium loading indicator — sized, subtle, and consistent.
/// Drop-in replacement for the banned `Center(child: CircularProgressIndicator())`.
class FxLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  const FxLoading({super.key, this.size = 28, this.strokeWidth = 2.5});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: strokeWidth),
      ),
    );
  }
}
