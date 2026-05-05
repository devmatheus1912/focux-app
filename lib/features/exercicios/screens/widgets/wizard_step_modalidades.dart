import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';

class WizardStepModalidades extends StatelessWidget {
  final Set<Modalidade> selecionadas;
  final ValueChanged<Modalidade> onToggle;

  const WizardStepModalidades({
    super.key,
    required this.selecionadas,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _WizardChoiceSection<Modalidade>(
      title: 'Que tipo de exercicio voce usa?',
      subtitle:
          'A biblioteca vem pronta, mas voce escolhe o que faz sentido agora.',
      values: Modalidade.values,
      selected: selecionadas,
      labels: TaxonomyLabels.modalidade,
      onToggle: onToggle,
    );
  }
}

class _WizardChoiceSection<T extends Enum> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> values;
  final Set<T> selected;
  final Map<T, String> labels;
  final ValueChanged<T> onToggle;

  const _WizardChoiceSection({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.selected,
    required this.labels,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in values)
              FilterChip(
                selected: selected.contains(value),
                label: Text(labels[value] ?? value.backendName),
                onSelected: (_) => onToggle(value),
              ),
          ],
        ),
      ],
    );
  }
}
