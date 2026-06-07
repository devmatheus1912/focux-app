import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';

class Aluno360MiniAutonomyChip extends StatelessWidget {
  const Aluno360MiniAutonomyChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Aluno360Layout.chipLabelStyle(context, color: color),
    );
  }
}
