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
