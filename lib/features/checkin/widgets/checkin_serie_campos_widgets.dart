import 'package:flutter/material.dart';


import '../../../core/theme/tokens_strip.dart';

/// Alvo mínimo de toque dos chips de sensação.
const double checkinFeedbackChipMin = 48;

class CheckinFeedbackChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const CheckinFeedbackChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: checkinFeedbackChipMin,
            minWidth: checkinFeedbackChipMin,
          ),
          padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.0 : 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

