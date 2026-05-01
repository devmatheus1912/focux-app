import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class DepoimentosSection extends StatelessWidget {
  final PublicPersonalData data;
  final Color primaryColor;

  const DepoimentosSection({
    super.key,
    required this.data,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!data.isEnterprise || data.depoimentos.isEmpty) {
      return const SizedBox.shrink();
    }
    final depoimentos =
        LandingDesign.prioritize(
          data.depoimentos,
          data.featuredTestimonialIndex,
        ).take(5).toList();

    return Container(
      color: const Color(0xFF070B16),
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROVA REAL',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'O que alunos sentem no acompanhamento.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < depoimentos.length; i++)
                _TestimonialTile(
                  item: depoimentos[i],
                  featured: i == 0,
                  primaryColor: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialTile extends StatelessWidget {
  final PublicDepoimentoItem item;
  final bool featured;
  final Color primaryColor;

  const _TestimonialTile({
    required this.item,
    required this.featured,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(featured ? 18 : 14),
      decoration: BoxDecoration(
        color: featured ? const Color(0xFF121D31) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              featured
                  ? primaryColor.withValues(alpha: 0.42)
                  : const Color(0xFF1F2937),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: featured ? 18 : 14,
                backgroundColor: primaryColor.withValues(alpha: 0.3),
                child: Text(
                  item.nomeAluno.isNotEmpty
                      ? item.nomeAluno[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.nomeAluno,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: featured ? 15 : 13,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < item.nota ? Icons.star : Icons.star_border,
                    size: 14,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.texto,
            style: TextStyle(
              color: featured ? Colors.white : const Color(0xFF9CA3AF),
              fontSize: featured ? 15 : 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
