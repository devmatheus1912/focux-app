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
            'Entendemos objetivo, rotina, restricoes e historico para montar um plano com contexto.',
      ),
      (
        titulo: 'Treino personalizado',
        descricao:
            'Cada fase respeita seu nivel atual e ajusta carga, frequencia e progressao.',
      ),
      (
        titulo: 'Acompanhamento de perto',
        descricao:
            'Feedback, ajustes e comunicacao no app para nao deixar voce treinar no escuro.',
      ),
      (
        titulo: 'Consistencia e resultado',
        descricao:
            'O foco deixa de ser motivacao passageira e vira rotina com direcao clara.',
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
                    'A jornada nao parece uma ficha. Parece um acompanhamento.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.slogan?.trim().isNotEmpty == true
                        ? data.slogan!
                        : 'Sem improviso, sem planilha solta e sem acompanhamento generico.',
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
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0$index',
            style: TextStyle(
              color: primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
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
