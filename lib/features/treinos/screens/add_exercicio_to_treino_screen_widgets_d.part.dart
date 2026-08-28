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
                    ? 'Vale para buscar, explorar e adições rápidas.'
                    : 'Ajuste séries, carga e descanso antes de salvar.',
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

class _AddExerciseSectionHeader extends StatelessWidget {
  const _AddExerciseSectionHeader({
    required this.title,
    this.subtitle,
    this.onHelp,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: FxSettingsLayout.headerToGroup),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FxSettingsLayout.sectionHeader(color: mute),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: FxSettingsLayout.captionAfterHeader),
                  Text(
                    subtitle!,
                    style: FxSettingsLayout.footer(color: mute),
                  ),
                ],
              ],
            ),
          ),
          if (onHelp != null)
            FxHelpIconButton(
              tooltip: 'Ajuda sobre $title',
              onTap: onHelp!,
              size: 28,
            ),
        ],
      ),
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

  static const _tabs = [
    (
      label: 'Buscar',
      icon: Icons.search_rounded,
      semantics: 'Buscar exercício pelo nome',
    ),
    (
      label: 'Explorar',
      icon: Icons.explore_outlined,
      semantics: 'Explorar por categoria',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final tabMotionMs = fxMotionDurationMs(context, normal: 180);

    return Semantics(
      container: true,
      label: 'Como adicionar: buscar ou explorar',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: fxListCardDecoration(
          context,
          accent: primary,
          radius: FxSettingsLayout.groupRadius,
        ),
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selectedIndex == i,
                  label: _tabs[i].semantics,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: tabMotionMs),
                      curve: Curves.easeOutCubic,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedIndex == i ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            selectedIndex == i
                                ? [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.22),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                                : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _tabs[i].icon,
                            size: 18,
                            color: selectedIndex == i ? Colors.white : mute,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _tabs[i].label,
                            style: FocuxHubTypography.body(
                              color: selectedIndex == i ? Colors.white : mute,
                            ).copyWith(
                              fontWeight:
                                  selectedIndex == i
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                              letterSpacing: -0.1,
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
      header: 'Mais opções',
      helpTooltip: 'Ajuda sobre a biblioteca',
      onHelpTap: () => showAddExercicioHelpSheet(context),
      children: [
        FxSettingsTile(
          icon: Icons.library_books_outlined,
          accent: primary,
          label: 'Biblioteca completa ($totalCount)',
          subtitle: libraryLines.primary,
          semanticsLabel:
              'Biblioteca completa com $totalCount exercícios. ${libraryLines.primary}',
          value: '',
          onTap: onOpenPicker,
        ),
        FxSettingsTile(
          icon: Icons.add_rounded,
          accent: primary,
          label: createLabel,
          subtitle: 'Grave o vídeo de execução para o aluno',
          semanticsLabel: '$createLabel. Grave o vídeo de execução para o aluno',
          value: '',
          highlight: true,
          showDivider: false,
          onTap: onCreate,
        ),
      ],
    );
  }
}
