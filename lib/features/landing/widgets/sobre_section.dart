import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class SobreSection extends StatelessWidget {
  final PublicPersonalData data;
  const SobreSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.descricaoProfissional == null ||
        data.descricaoProfissional!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOBRE',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.logoUrl != null && data.isEnterprise)
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(data.logoUrl!),
                      )
                    else
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF3B5FE2),
                        child: Text(
                          data.nomePersonal.isNotEmpty
                              ? data.nomePersonal[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.descricaoProfissional!,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.people_outline,
                      text: '${data.totalAlunos}+ alunos',
                    ),
                    _InfoPill(
                      icon: Icons.calendar_today_outlined,
                      text: 'Desde ${data.anoCriacao}',
                    ),
                    if (data.cref?.trim().isNotEmpty == true)
                      const _InfoPill(
                        icon: Icons.verified_outlined,
                        text: 'CREF ativo',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF3B5FE2), size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
