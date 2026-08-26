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
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
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
                  style: TextStyle(
                    color: ready ? ink : mute,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: action.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$progress/2',
                  style: TextStyle(
                    color: action,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: _ProgressStep(done: hasName, isDark: isDark)),
              const SizedBox(width: 8),
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
      height: 4,
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
  final bool isDark;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _FxFormField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.hint,
    this.helper,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: mute,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            color: ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 22,
              color: BrandPalette.softened(primary),
            ),
            filled: true,
            fillColor:
                isDark
                    ? EagleTokens.darkCardHi
                    : TokensStrip.pageBg.withValues(alpha: 0.78),
            hintStyle: TextStyle(color: mute.withValues(alpha: 0.62)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: line),
            ),
            enabledBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: line),
            ),
            focusedBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: primary.withValues(alpha: 0.68),
                width: 1.5,
              ),
            ),
            errorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: EagleTokens.bad),
            ),
            focusedErrorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: EagleTokens.bad, width: 1.3),
            ),
            errorStyle: const TextStyle(color: EagleTokens.bad, fontSize: 11),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(color: mute, fontSize: 11.5, height: 1.25),
          ),
        ],
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final bool isDark;

  const _LabelRow({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color:
              selected
                  ? action.withValues(alpha: isDark ? 0.18 : 0.11)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : BrandPalette.soft(primary, dark: false)),
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          border: Border.all(
            color:
                selected
                    ? action.withValues(alpha: 0.42)
                    : line.withValues(alpha: 0.85),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14, color: action),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: FocuxHubTypography.chip(
                selected ? action : ink,
              ).copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ErrorCard extends StatelessWidget {
  final String message;
  final bool isDark;

  const _ErrorCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: EagleTokens.bad,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
