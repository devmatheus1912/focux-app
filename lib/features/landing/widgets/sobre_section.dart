import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class SobreSection extends StatelessWidget {
  final PublicPersonalData data;
  const SobreSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.descricaoProfissional == null || data.descricaoProfissional!.isEmpty) {
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
                    data.nomePersonal.isNotEmpty ? data.nomePersonal[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.descricaoProfissional!,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
