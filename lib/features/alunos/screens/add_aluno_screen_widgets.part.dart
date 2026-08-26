part of 'add_aluno_screen.dart';

class _AccessProgressStrip extends StatelessWidget {
  final String name;
  final bool hasName;
  final bool hasEmail;
  final bool isDark;

  const _AccessProgressStrip({
    required this.name,
    required this.hasName,
    required this.hasEmail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final ready = hasName && hasEmail;
    final progress = (hasName ? 1 : 0) + (hasEmail ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ready
                      ? 'Convite pronto para $name'
                      : 'Preencha nome e e-mail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FxSettingsLayout.subhead(
                    color: ready ? ink : mute,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$progress/2',
                style: FxSettingsLayout.rowMetric(color: mute),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Row(
            children: [
              Expanded(child: _ProgressStep(done: hasName, isDark: isDark)),
              const SizedBox(width: TokensStrip.s2),
              Expanded(child: _ProgressStep(done: hasEmail, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final bool done;
  final bool isDark;

  const _ProgressStep({required this.done, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: done ? action : line.withValues(alpha: isDark ? 0.7 : 0.75),
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
      ),
    );
  }
}

class _FxFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _FxFormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: FxInputDeco.build(
        context,
        label,
        icon: icon,
        hint: hint,
        iconColor: BrandPalette.softened(primary),
        iconSize: FxSettingsLayout.iconSize,
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool showDividerAbove;
  final Widget child;

  const _ChoiceSection({
    required this.label,
    required this.isDark,
    required this.child,
    this.showDividerAbove = false,
  });

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDividerAbove) ...[
          const SizedBox(height: TokensStrip.s3),
          Divider(
            height: 1,
            thickness: FxSettingsLayout.dividerThickness,
            color: line.withValues(alpha: isDark ? 0.55 : 0.7),
          ),
          const SizedBox(height: TokensStrip.s3),
        ] else
          const SizedBox(height: TokensStrip.s2),
        Text(
          label,
          style: FxSettingsLayout.subhead(
            color: mute,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 11),
        ),
        const SizedBox(height: TokensStrip.s2),
        child,
        const SizedBox(height: TokensStrip.s2),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<Widget> children;

  const _ChipWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  final List<({String value, String label})> options;
  final String? selected;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _SegmentedChoice({
    required this.options,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        border: Border.all(color: line.withValues(alpha: isDark ? 0.7 : 0.85)),
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: FxSettingsLayout.dividerThickness,
                  color: line.withValues(alpha: isDark ? 0.55 : 0.7),
                ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(options[i].value),
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0
                          ? Radius.circular(TokensStrip.rSm - 1)
                          : Radius.zero,
                      right: i == options.length - 1
                          ? Radius.circular(TokensStrip.rSm - 1)
                          : Radius.zero,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      color:
                          selected == options[i].value
                              ? action.withValues(alpha: isDark ? 0.16 : 0.10)
                              : Colors.transparent,
                      child: Text(
                        options[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: FocuxHubTypography.chip(
                          selected == options[i].value ? action : ink,
                        ).copyWith(
                          fontSize: 12,
                          fontWeight:
                              selected == options[i].value
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected
                    ? action.withValues(alpha: isDark ? 0.16 : 0.10)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(TokensStrip.rPill),
            border: Border.all(
              color:
                  selected
                      ? action.withValues(alpha: 0.5)
                      : line.withValues(alpha: 0.85),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.chip(
              selected ? action : ink,
            ).copyWith(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
