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
    final mute = fxScreenMute(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
          child: Text(
            'Perfil rápido',
            style: FxSettingsLayout.sectionHeader(color: mute),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
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
                    horizontal: 8,
                    vertical: 6,
                  ),
                  labelStyle: TextStyle(
                    color:
                        selectedLabel == setup.label ? Colors.white : primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(color: primary.withValues(alpha: 0.16)),
                  selectedColor: primary,
                  backgroundColor: primary.withValues(alpha: 0.06),
                ),
              ),
          ],
        ),
        Divider(
          height: 1,
          thickness: FxSettingsLayout.dividerThickness,
          color: ShellChrome.of(context).line,
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);

    return FxSettingsGroup(
      accent: primary,
      children: [
        FxSettingsTile(
          icon: icon,
          accent: soft,
          label: title,
          subtitle: subtitle,
          value: '',
          picker: true,
          showDivider: expanded,
          onTap: onToggle,
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: child,
          ),
      ],
    );
  }
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final T? value;
  final List<T> values;
  final Map<T, String> labels;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final double? menuMaxHeight;
  final bool showDivider;

  const _EnumDropdown({
    required this.label,
    required this.icon,
    this.iconColor,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
    this.validator,
    this.menuMaxHeight,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final effectiveValue = value ?? state.value;
        final selectedLabel =
            effectiveValue == null
                ? 'Selecionar'
                : labels[effectiveValue] ?? effectiveValue.backendName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxInsetPickerRow(
              icon: icon,
              iconColor: iconColor,
              label: label,
              value: selectedLabel,
              showDivider: showDivider && state.errorText == null,
              semanticsLabel:
                  effectiveValue == null
                      ? '$label, não selecionado'
                      : '$label, ${labels[effectiveValue] ?? effectiveValue.backendName}',
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
            ),
            if (state.errorText != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showDivider)
                Divider(
                  height: 1,
                  thickness: FxSettingsLayout.dividerThickness,
                  color: ShellChrome.of(context).line,
                ),
            ],
          ],
        );
      },
    );
  }
}
