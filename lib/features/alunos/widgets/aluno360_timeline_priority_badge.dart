import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';
import '../utils/aluno360_timeline_logic.dart';

/// Semantic P0–P3 badge for timeline events.
class Aluno360TimelinePriorityBadge extends StatelessWidget {
  const Aluno360TimelinePriorityBadge({
    super.key,
    required this.priority,
    required this.accent,
    required this.isDark,
  });

  final String priority;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label =
        priority.trim().isEmpty ? 'P2' : priority.trim().toUpperCase();
    final color = timeline360PriorityColor(label, primary: accent);
    final ink = timeline360PriorityInk(color, isDark: isDark);
    final isP0 = label.startsWith('P0');
    final bgAlpha = isP0 ? (isDark ? 0.30 : 0.24) : (isDark ? 0.22 : 0.14);
    return Semantics(
      label: 'Prioridade $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: ink.withValues(alpha: isDark ? 0.55 : 0.38),
          ),
        ),
        child: Text(
          label,
          style: Aluno360Layout.chipLabelStyle(context, color: ink).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
