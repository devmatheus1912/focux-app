import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class DepoimentosSection extends StatelessWidget {
  final PublicPersonalData data;
  final Color primaryColor;
  
  const DepoimentosSection({super.key, required this.data, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    if (!data.isEnterprise || data.depoimentos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEPOIMENTOS',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: data.depoimentos.take(5).map((d) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primaryColor.withValues(alpha: 0.3),
                      child: Text(d.nomeAluno.isNotEmpty ? d.nomeAluno[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d.nomeAluno,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                    Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(
                      i < d.nota ? Icons.star : Icons.star_border,
                      size: 14,
                      color: const Color(0xFFF59E0B),
                    ))),
                  ]),
                  const SizedBox(height: 8),
                  Text(d.texto,
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.5)),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
