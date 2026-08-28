part of 'add_exercicio_to_treino_screen.dart';

class _PrescriptionSectionHeader extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool globalPresetMode;

  const _PrescriptionSectionHeader({
    required this.isDark,
    required this.primary,
    this.globalPresetMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.edit_note_rounded, color: primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                globalPresetMode
                    ? 'Prescrição padrão do treino'
                    : 'Prescrição do exercício',
                style: FocuxHubTypography.body(color: ink).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                globalPresetMode
                    ? 'Vale para explorar, modelos e adições rápidas.'
                    : 'Ajuste séries, carga, descanso e observações antes de salvar.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddExerciseTabStrip extends StatelessWidget {
  final int selectedIndex;
  final Color primary;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _AddExerciseTabStrip({
    required this.selectedIndex,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  static const _labels = ['Buscar', 'Explorar'];
  static const _semanticsLabels = [
    'Buscar, buscar por nome',
    'Explorar, explorar por movimento',
  ];

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final tabMotionMs = fxMotionDurationMs(context, normal: 180);

    return Semantics(
      container: true,
      label: 'Abas de adicionar exercício',
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: line.withValues(alpha: 0.72))),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selectedIndex == i,
                  label: _semanticsLabels[i],
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _labels[i],
                            style: FocuxHubTypography.bodyMuted(
                              color: selectedIndex == i ? primary : mute,
                              fontWeight:
                                  selectedIndex == i
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                            ).copyWith(letterSpacing: -0.1),
                          ),
                          const SizedBox(height: 10),
                          AnimatedContainer(
                            duration: Duration(milliseconds: tabMotionMs),
                            width: selectedIndex == i ? 40 : 0,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrowseLibraryCta extends StatelessWidget {
  const _BrowseLibraryCta({
    required this.totalCount,
    required this.libraryLines,
    required this.libraryCaption,
    required this.createLabel,
    required this.isDark,
    required this.primary,
    required this.onOpenPicker,
    required this.onCreate,
  });

  final int totalCount;
  final ExercisePickerLibraryLines libraryLines;
  final String libraryCaption;
  final String createLabel;
  final bool isDark;
  final Color primary;
  final VoidCallback onOpenPicker;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return FxSettingsGroup(
      accent: primary,
      caption: libraryCaption,
      children: [
        FxSettingsTile(
          icon: Icons.library_books_outlined,
          accent: primary,
          label: 'Ver biblioteca ($totalCount)',
          subtitle: libraryLines.primary,
          semanticsLabel:
              'Ver biblioteca com $totalCount exercícios. ${libraryLines.primary}',
          value: '',
          onTap: onOpenPicker,
        ),
        FxSettingsTile(
          icon: Icons.add_rounded,
          accent: primary,
          label: createLabel,
          subtitle: 'Cadastre e envie vídeo de demonstração',
          semanticsLabel: '$createLabel. Cadastre e envie vídeo de demonstração',
          value: '',
          highlight: true,
          showDivider: false,
          onTap: onCreate,
        ),
      ],
    );
  }
}
