import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';
import '../utils/aluno360_timeline_logic.dart';

class Aluno360MiniAutonomyChip extends StatelessWidget {
  const Aluno360MiniAutonomyChip({
    super.key,
    required this.label,
    required this.color,
    this.isDark = false,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark || Theme.of(context).brightness == Brightness.dark;
    final ink = timeline360PriorityInk(color, isDark: dark);
    return Semantics(
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: Aluno360Layout.miniChipDecoration(color, isDark: dark),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Aluno360Layout.chipLabelStyle(
              context,
              color: ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
