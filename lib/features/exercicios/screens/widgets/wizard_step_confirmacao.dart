import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';

class WizardStepConfirmacao extends StatelessWidget {
  final Set<Modalidade> modalidades;
  final Set<Espaco> espacos;
  final AsyncSnapshot<Map<String, dynamic>> preview;

  const WizardStepConfirmacao({
    super.key,
    required this.modalidades,
    required this.espacos,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final total = (preview.data?['totalCandidatos'] as num?)?.toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmar biblioteca',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Vamos carregar exercicios com taxonomia pronta. Videos entram para curadoria quando ainda nao forem seus.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _SummaryCard(
          title:
              preview.connectionState == ConnectionState.waiting
                  ? 'Calculando...'
                  : '${total ?? 0} exercicios encontrados',
          subtitle: [
            modalidades
                .map((m) => TaxonomyLabels.modalidade[m])
                .whereType<String>()
                .join(', '),
            espacos
                .map((e) => TaxonomyLabels.espaco[e])
                .whereType<String>()
                .join(', '),
          ].where((e) => e.isNotEmpty).join('\n'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SummaryCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(subtitle),
          ],
        ],
      ),
    );
  }
}
