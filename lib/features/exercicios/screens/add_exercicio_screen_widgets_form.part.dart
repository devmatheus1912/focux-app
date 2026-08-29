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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = fxScreenMute(context);
    final line = ShellChrome.of(context).line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Perfil rápido',
                  style: FxSettingsLayout.sectionHeader(color: mute),
                ),
              ),
              FxHelpIconButton(
                tooltip: 'Ajuda sobre perfil rápido',
                onTap: () => showNovoExercicioPerfilRapidoHelpSheet(context),
                size: 28,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) const SizedBox(height: 6),
                Row(
                  children: [
                    for (var col = 0; col < 2; col++) ...[
                      if (col > 0) const SizedBox(width: 6),
                      Expanded(
                        child: FxToggleChip(
                          expanded: true,
                          label: _quickSetups[row * 2 + col].label,
                          icon: _quickSetups[row * 2 + col].icon,
                          selected:
                              selectedLabel ==
                              _quickSetups[row * 2 + col].label,
                          isDark: isDark,
                          filledWhenSelected: true,
                          onTap:
                              () => onSelected(_quickSetups[row * 2 + col]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: FxSettingsLayout.dividerThickness,
          color: line,
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
  final String? helpTooltip;
  final VoidCallback? onHelpTap;

  const _CollapsibleSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.expanded,
    required this.onToggle,
    this.helpTooltip,
    this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);

    return FxSettingsGroup(
      header: title,
      caption: subtitle,
      helpTooltip: helpTooltip,
      onHelpTap: onHelpTap,
      accent: primary,
      children: [
        FxSettingsTile(
          icon: icon,
          accent: soft,
          label: expanded ? 'Recolher campos' : 'Adicionar orientação',
          subtitle:
              expanded
                  ? 'Toque para esconder descrição, erros e contraindicações.'
                  : 'Opcional — aparece para o aluno na ficha do exercício.',
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
  final bool showDivider;
  final String sheetContextLabel;

  const _EnumDropdown({
    required this.label,
    required this.icon,
    this.iconColor,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
    required this.sheetContextLabel,
    this.validator,
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
                final picked = await showAddExercicioEnumPicker<T>(
                  context,
                  title: label,
                  contextLabel: sheetContextLabel,
                  icon: icon,
                  iconColor: iconColor,
                  values: values,
                  labels: labels,
                  selected: effectiveValue,
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
