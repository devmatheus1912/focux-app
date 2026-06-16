part of 'add_exercicio_screen.dart';

class _ChoiceGroup<T extends Enum> extends StatelessWidget {
  final List<T> values;
  final Set<T> selected;
  final Map<T, String> labels;
  final ValueChanged<T> onToggle;

  const _ChoiceGroup({
    required this.values,
    required this.selected,
    required this.labels,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final selectedValues =
        values.where((value) => selected.contains(value)).toList();
    final availableValues =
        values.where((value) => !selected.contains(value)).toList();

    Widget chipFor(T value, {required bool isSelected}) {
      final label = labels[value] ?? value.backendName;
      return Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onToggle(value),
          showCheckmark: isSelected,
          checkmarkColor: Colors.white,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 10 : 9,
            vertical: isSelected ? 7 : 6,
          ),
          labelStyle: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary),
            fontSize: isSelected ? 12 : 11.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          ),
          selectedColor: primary,
          backgroundColor:
              isDark
                  ? Colors.white.withValues(alpha: 0.035)
                  : TokensStrip.pageBg,
          side: BorderSide(
            color:
                isSelected
                    ? primary
                    : (isDark
                        ? EagleTokens.darkLine
                        : TokensStrip.borderDefault.withValues(alpha: 0.72)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedValues.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in selectedValues)
                chipFor(value, isSelected: true),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.035)
                      : TokensStrip.pageBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark
                        ? EagleTokens.darkLine
                        : TokensStrip.borderDefault.withValues(alpha: 0.72),
              ),
            ),
            child: Text(
              'Nenhum selecionado',
              style: TextStyle(
                color: mute,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (availableValues.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Adicionar',
            style: TextStyle(
              color: mute,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in availableValues)
                chipFor(value, isSelected: false),
            ],
          ),
        ],
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final int count;

  const _GroupLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final mute =
        Theme.of(context).brightness == Brightness.dark
            ? EagleTokens.darkInkMute
            : TokensStrip.textSecondary;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: mute,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count > 0)
          Text(
            '$count selecionado${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: fxListCardDecoration(context),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          isDark
                              ? EagleTokens.darkInkMute
                              : TokensStrip.textSecondary,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
