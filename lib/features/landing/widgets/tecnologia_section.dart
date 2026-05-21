import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class TecnologiaSection extends StatelessWidget {
  final PublicPersonalData data;
  final Color primaryColor;
  final Color secondaryColor;

  const TecnologiaSection({
    super.key,
    required this.data,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final itens = [
      'Treino estruturado por fase, dia e prioridade.',
      'Check-ins e progresso para medir evolucao real.',
      'Chat direto no app para reduzir ruido.',
      'Experiencia com a identidade do personal.',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F1419),
              primaryColor.withValues(alpha: 0.24),
              secondaryColor.withValues(alpha: 0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APP E ROTINA',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'O treino tambem vive no app.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sem PDF perdido em conversa. O aluno recebe rotina acompanhada, historico claro e ajustes continuos.',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            for (final item in itens)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: primaryColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureMiniCard(
                          icon: Icons.fitness_center,
                          title: 'Treinos',
                          subtitle: 'Execucao guiada',
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FeatureMiniCard(
                          icon: Icons.show_chart,
                          title: 'Progresso',
                          subtitle: 'Historico claro',
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureMiniCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Chat',
                          subtitle: 'Contato direto',
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FeatureMiniCard(
                          icon: Icons.task_alt,
                          title: 'Check-in',
                          subtitle: 'Consistencia',
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
