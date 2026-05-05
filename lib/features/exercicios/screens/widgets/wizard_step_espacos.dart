import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';

class WizardStepEspacos extends StatelessWidget {
  final Set<Espaco> selecionados;
  final ValueChanged<Espaco> onToggle;

  const WizardStepEspacos({
    super.key,
    required this.selecionados,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Onde seus alunos treinam?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Isso ajuda a filtrar exercicios por equipamentos e ambiente.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in Espaco.values)
              FilterChip(
                selected: selecionados.contains(value),
                label: Text(TaxonomyLabels.espaco[value] ?? value.backendName),
                onSelected: (_) => onToggle(value),
              ),
          ],
        ),
      ],
    );
  }
}
