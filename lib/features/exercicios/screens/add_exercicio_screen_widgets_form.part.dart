part of 'add_exercicio_screen.dart';

class _ExerciseQuickSetup {
  final String label;
  final IconData icon;
  final Modalidade modalidade;
  final Dificuldade dificuldade;
  final PadraoMovimento? padraoMovimento;
  final Set<Equipamento> equipamentos;
  final Set<Espaco> espacos;

  const _ExerciseQuickSetup({
    required this.label,
    required this.icon,
    required this.modalidade,
    required this.dificuldade,
    required this.padraoMovimento,
    required this.equipamentos,
    required this.espacos,
  });
}

const _quickSetups = [
  _ExerciseQuickSetup(
    label: 'Academia',
    icon: Icons.apartment_rounded,
    modalidade: Modalidade.musculacao,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: null,
    equipamentos: {
      Equipamento.halter,
      Equipamento.barra,
      Equipamento.maquina,
      Equipamento.polia,
      Equipamento.banco,
    },
    espacos: {Espaco.academiaCompleta, Espaco.academiaBasica},
  ),
  _ExerciseQuickSetup(
    label: 'Casa',
    icon: Icons.home_work_rounded,
    modalidade: Modalidade.musculacao,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: null,
    equipamentos: {
      Equipamento.halter,
      Equipamento.kettlebell,
      Equipamento.banda,
      Equipamento.pesoCorporal,
    },
    espacos: {Espaco.casaEquipada},
  ),
  _ExerciseQuickSetup(
    label: 'Peso corporal',
    icon: Icons.accessibility_new_rounded,
    modalidade: Modalidade.musculacao,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: null,
    equipamentos: {Equipamento.pesoCorporal},
    espacos: {Espaco.casaSemEquipo, Espaco.outdoor},
  ),
  _ExerciseQuickSetup(
    label: 'Mobilidade',
    icon: Icons.self_improvement_rounded,
    modalidade: Modalidade.mobilidade,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: PadraoMovimento.mobilidadeDinamica,
    equipamentos: {Equipamento.pesoCorporal, Equipamento.banda},
    espacos: {Espaco.academiaCompleta, Espaco.casaEquipada},
  ),
];

class _QuickSetupStrip extends StatelessWidget {
  final String? selectedLabel;
  final ValueChanged<_ExerciseQuickSetup> onSelected;

  const _QuickSetupStrip({
    required this.selectedLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil rápido',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final setup in _quickSetups)
              Semantics(
                button: true,
                selected: selectedLabel == setup.label,
                label: 'Perfil rápido ${setup.label}',
                child: FilterChip(
                  avatar: Icon(
                    setup.icon,
                    color:
                        selectedLabel == setup.label ? Colors.white : primary,
                    size: 16,
                  ),
                  label: Text(setup.label),
                  selected: selectedLabel == setup.label,
                  onSelected: (_) => onSelected(setup),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  labelStyle: TextStyle(
                    color:
                        selectedLabel == setup.label ? Colors.white : primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  side: BorderSide(color: primary.withValues(alpha: 0.16)),
                  selectedColor: primary,
                  backgroundColor:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : primary.withValues(alpha: 0.06),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool expanded;
  final VoidCallback? onToggle;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.expanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final collapsed = onToggle != null && !expanded;
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: collapsed ? 0.07 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
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
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onToggle != null) ...[
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color:
                  isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
            ),
          ),
        ],
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(collapsed ? 12 : 14),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onToggle == null)
            header
          else
            Semantics(
              button: true,
              expanded: expanded,
              label:
                  expanded ? 'Recolher $title' : 'Expandir $title. $subtitle',
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: header,
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child:
                expanded
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color:
                              isDark
                                  ? EagleTokens.darkLine
                                  : TokensStrip.borderDefault.withValues(
                                    alpha: 0.58,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        child,
                      ],
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextInput({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor:
            Theme.of(context).brightness == Brightness.dark
                ? EagleTokens.darkCard
                : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? EagleTokens.darkLine
                    : TokensStrip.borderDefault,
          ),
        ),
      ),
    );
  }
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> values;
  final Map<T, String> labels;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final double? menuMaxHeight;

  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
    this.validator,
    this.menuMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? EagleTokens.darkCard : Colors.white;
    final borderColor =
        isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final effectiveValue = value ?? state.value;
        final selectedLabel =
            effectiveValue == null
                ? ''
                : labels[effectiveValue] ?? effectiveValue.backendName;
        return Semantics(
          button: true,
          label:
              effectiveValue == null
                  ? '$label, não selecionado'
                  : '$label, ${labels[effectiveValue] ?? effectiveValue.backendName}',
          child: InkWell(
            onTap: () async {
              final useCompactPicker = values.length <= 4;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final pageBg = isDark ? EagleTokens.darkBg : TokensStrip.pageBg;
              final picked = await showGeneralDialog<T>(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Fechar seletor de $label',
                barrierColor: Colors.black.withValues(alpha: 0.68),
                transitionDuration: const Duration(milliseconds: 180),
                pageBuilder:
                    (context, _, __) => Material(
                      color: useCompactPicker ? Colors.transparent : pageBg,
                      child:
                          useCompactPicker
                              ? _EnumPickerCompact<T>(
                                title: label,
                                values: values,
                                labels: labels,
                                selected: effectiveValue,
                              )
                              : _EnumPickerFullScreen<T>(
                                title: label,
                                values: values,
                                labels: labels,
                                selected: effectiveValue,
                                maxHeight: menuMaxHeight ?? 720,
                              ),
                    ),
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        ),
              );
              if (picked != null) {
                state.didChange(picked);
                onChanged(picked);
              }
            },
            borderRadius: BorderRadius.circular(15),
            child: InputDecorator(
              isEmpty: effectiveValue == null,
              decoration: InputDecoration(
                labelText: effectiveValue == null ? null : label,
                hintText: effectiveValue == null ? label : null,
                errorText: state.errorText,
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                enabledBorder: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            effectiveValue == null
                                ? (isDark
                                    ? EagleTokens.darkInkMute
                                    : TokensStrip.textSecondary)
                                : (isDark
                                    ? EagleTokens.darkInk
                                    : TokensStrip.textPrimary),
                        fontWeight:
                            effectiveValue == null
                                ? FontWeight.w500
                                : FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color:
                        isDark
                            ? EagleTokens.darkInkMute
                            : TokensStrip.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

