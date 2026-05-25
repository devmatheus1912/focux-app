import 'package:flutter/material.dart';


/// Destaca o termo buscado no nome do exercício.
Widget highlightedExerciseName({
  required String name,
  required String query,
  required TextStyle baseStyle,
  required Color highlightColor,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: baseStyle);
  }

  final lower = name.toLowerCase();
  final index = lower.indexOf(normalized);
  if (index < 0) {
    return Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: baseStyle);
  }

  final before = name.substring(0, index);
  final match = name.substring(index, index + normalized.length);
  final after = name.substring(index + normalized.length);

  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: before, style: baseStyle),
        TextSpan(
          text: match,
          style: baseStyle.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.w900,
            backgroundColor: highlightColor.withValues(alpha: 0.12),
          ),
        ),
        TextSpan(text: after, style: baseStyle),
      ],
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}
