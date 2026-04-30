import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/landing_tracking.dart';
import '../models/public_personal_data.dart';

class OfertasSection extends StatelessWidget {
  final PublicPersonalData data;
  final String slug;
  final Color primaryColor;

  const OfertasSection({
    super.key,
    required this.data,
    required this.slug,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.servicos.isEmpty && data.pacotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.servicos.isNotEmpty) ...[
            const Text(
              'SERVICOS',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            for (final servico in data.servicos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servico.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (servico.descricao.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          servico.descricao,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
          ],
          if (data.pacotes.isNotEmpty) ...[
            const Text(
              'PLANOS E VALORES',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            for (final pacote in data.pacotes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              pacote.nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (pacote.preco.trim().isNotEmpty)
                            Text(
                              pacote.preco,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                      if (pacote.descricao.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          pacote.descricao,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final path = landingRegisterPath(
                              slug,
                              data.trackingId,
                              source: 'landing_offer',
                            );
                            trackLandingEvent(
                              slug: slug,
                              eventType: 'landing_cta_click',
                              source: 'landing_offer',
                              trackingId: data.trackingId,
                              path: path,
                            );
                            context.go(path);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            pacote.cta.trim().isNotEmpty
                                ? pacote.cta
                                : 'Quero esse plano',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
