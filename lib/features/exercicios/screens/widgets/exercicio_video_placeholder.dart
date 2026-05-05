import 'package:flutter/material.dart';

class ExercicioVideoPlaceholder extends StatelessWidget {
  const ExercicioVideoPlaceholder({super.key, this.size = 54});

  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.videocam_off_rounded, color: primary),
    );
  }
}
