part of 'add_aluno_screen.dart';

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final accent = BrandPalette.sectionAccent(primary, dark: isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 16, 16, 18),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: mute, fontSize: 12, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          ...children,
        ],
      ),
    );
  }
}

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
      height: 5,
      decoration: BoxDecoration(
        color: done ? action : line.withValues(alpha: isDark ? 0.7 : 0.75),
        borderRadius: BorderRadius.circular(999),
        boxShadow:
            done
                ? [
                  BoxShadow(
                    color: action.withValues(alpha: isDark ? 0.55 : 0.42),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.32),
                    blurRadius: 6,
                    spreadRadius: -2,
                  ),
                ]
                : null,
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
            prefixIcon: Icon(icon, size: 19, color: mute),
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
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:
              selected
                  ? action.withValues(alpha: isDark ? 0.22 : 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : TokensStrip.pageBg),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? action.withValues(alpha: 0.58) : line,
            width: selected ? 1.4 : 1.0,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: action.withValues(alpha: isDark ? 0.28 : 0.18),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 15, color: action),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? action : ink,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitePreviewCard extends StatelessWidget {
  final bool isDark;
  final String name;
  final bool hasWhatsapp;
  final String? consultoriaLabel;

  const _InvitePreviewCard({
    required this.isDark,
    required this.name,
    required this.hasWhatsapp,
    this.consultoriaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fluxo pós-cadastro',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$name entra na lista de alunos e recebe acesso com senha provisória.',
                      style: TextStyle(color: mute, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewBadge(
                icon: Icons.password_rounded,
                label: 'Senha provisória',
                isDark: isDark,
              ),
              _PreviewBadge(
                icon:
                    hasWhatsapp
                        ? Icons.send_to_mobile_rounded
                        : Icons.content_copy_rounded,
                label: hasWhatsapp ? 'WhatsApp pronto' : 'Mensagem copiável',
                isDark: isDark,
              ),
              if (consultoriaLabel != null)
                _PreviewBadge(
                  icon: Icons.co_present_rounded,
                  label: consultoriaLabel!,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _PreviewBadge({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
        color: EagleTokens.bad.withValues(alpha: 0.1),
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
              style: const TextStyle(color: EagleTokens.bad, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSubmitBar extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool canSubmit;
  final bool loading;
  final String helper;
  final VoidCallback onSubmit;

  const _BottomSubmitBar({
    required this.isDark,
    required this.primary,
    required this.canSubmit,
    required this.loading,
    required this.helper,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(TokensStrip.s5, canSubmit ? 9 : 8, 20, 12),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkBg : TokensStrip.pageBg,
          border: Border(top: BorderSide(color: line.withValues(alpha: 0.65))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canSubmit) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.10 : 0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: mute),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        helper,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mute,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                helper,
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 11, height: 1.2),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSubmit,
                    borderRadius: BorderRadius.circular(17),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: primary),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child:
                          loading
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: FxLoading(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cadastrar aluno',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
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
