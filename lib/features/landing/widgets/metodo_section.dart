import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class MetodoSection extends StatelessWidget {
  final PublicPersonalData data;
  final Color primaryColor;

  const MetodoSection({
    super.key,
    required this.data,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final etapas = [
      (
        titulo: 'Diagnostico inicial',
        descricao:
            'Objetivo, rotina, restricoes e historico entram no plano antes da primeira serie.',
      ),
      (
        titulo: 'Treino personalizado',
        descricao: 'Fases, carga, frequencia e progressao viram criterio.',
      ),
      (
        titulo: 'Acompanhamento de perto',
        descricao: 'Feedback, check-ins e chat mantem orientacao clara.',
      ),
      (
        titulo: 'Consistencia e resultado',
        descricao: 'A evolucao fica visivel para manter progresso com clareza.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        final horizontalPadding = wide ? 112.0 : 32.0;
        final contentWidth =
            (constraints.maxWidth - horizontalPadding)
                .clamp(0.0, 1100.0)
                .toDouble();
        final cardWidth = wide ? (contentWidth - 36) / 4 : contentWidth;
        return Container(
          padding: EdgeInsets.fromLTRB(wide ? 56 : 16, 34, wide ? 56 : 16, 22),
          decoration: const BoxDecoration(color: Color(0xFF070B16)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'METODO PREMIUM',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Processo claro. Acompanhamento de verdade.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cada etapa mostra o que fazer, quando ajustar e como medir progresso.',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < etapas.length; i++)
                        SizedBox(
                          width: cardWidth,
                          child: _MetodoCard(
                            index: i + 1,
                            title: etapas[i].titulo,
                            description: etapas[i].descricao,
                            primaryColor: primaryColor,
                          ),
                        ),
                    ],
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

class _MetodoCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final Color primaryColor;

  const _MetodoCard({
    required this.index,
    required this.title,
    required this.description,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.30),
                  ),
                ),
                child: Text(
                  '0$index',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
