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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'METODO',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Um processo claro para transformar treino em resultado.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.slogan?.trim().isNotEmpty == true
                ? data.slogan!
                : 'Sem improviso, sem planilha solta e sem acompanhamento generico.',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < etapas.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          etapas[i].titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          etapas[i].descricao,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ],
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
