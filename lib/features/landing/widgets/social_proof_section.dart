import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class SocialProofSection extends StatelessWidget {
  final PublicPersonalData data;
  const SocialProofSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final items = LandingDesign.proofItems(data);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 760;
        final horizontalPadding = wide ? 56.0 : 16.0;
        final contentWidth =
            (constraints.maxWidth - horizontalPadding * 2)
                .clamp(0.0, 1100.0)
                .toDouble();
        final itemWidth = wide ? (contentWidth - 24) / 3 : contentWidth;

        return Container(
          color: const Color(0xFF0A1014),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            wide ? 28 : 18,
            horizontalPadding,
            wide ? 26 : 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: itemWidth,
                      child: _BadgeChip(item: item, color: accent),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final LandingProofItem item;
  final Color color;

  const _BadgeChip({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
