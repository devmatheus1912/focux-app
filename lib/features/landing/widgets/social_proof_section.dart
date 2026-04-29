import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class SocialProofSection extends StatelessWidget {
  final PublicPersonalData data;
  const SocialProofSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BadgeChip(
              icon: Icons.people_outline,
              label: '${data.totalAlunos} alunos',
              color: accent,
            ),
            if (data.cref != null && data.cref!.isNotEmpty)
              _BadgeChip(
                icon: Icons.verified_outlined,
                label: 'CREF ativo',
                color: accent,
              ),
            _BadgeChip(
              icon: Icons.calendar_today_outlined,
              label: 'Desde ${data.anoCriacao}',
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
