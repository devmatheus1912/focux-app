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

    Widget chipFor(T value, {required bool isSelected}) {
      final label = labels[value] ?? value.backendName;
      return Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onToggle(value),
          showCheckmark: isSelected,
          checkmarkColor: Colors.white,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 9 : 8,
            vertical: 5,
          ),
          labelStyle: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final value in values) chipFor(value, isSelected: selected.contains(value)),
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
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: FxSettingsLayout.sectionHeader(color: mute),
          ),
        ),
        if (count > 0)
          Text(
            '$count',
            style: FxSettingsLayout.rowMetric(color: primary),
          ),
      ],
    );
  }
}
