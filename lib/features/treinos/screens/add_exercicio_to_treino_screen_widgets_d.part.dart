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

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: line.withValues(alpha: 0.72))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
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
                        duration: const Duration(milliseconds: 180),
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
        ],
      ),
    );
  }
}

class _BrowseLibraryCta extends StatelessWidget {
  const _BrowseLibraryCta({
    required this.totalCount,
    required this.libraryLines,
    required this.isDark,
    required this.primary,
    required this.onOpenPicker,
    required this.onCreate,
  });

  final int totalCount;
  final ExercisePickerLibraryLines libraryLines;
  final bool isDark;
  final Color primary;
  final VoidCallback onOpenPicker;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        final libraryButton = OutlinedButton.icon(
          onPressed: onOpenPicker,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: primary.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(Icons.library_books_outlined, color: primary, size: 20),
          label: Text(
            'Ver biblioteca ($totalCount)',
            style: FocuxHubTypography.cardTitle(color: primary).copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              libraryButton,
              const SizedBox(height: 8),
              _CreateExerciseButton(
                primary: primary,
                expand: true,
                onPressed: onCreate,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: libraryButton),
            const SizedBox(width: 10),
            _CreateExerciseButton(
              primary: primary,
              compact: true,
              onPressed: onCreate,
            ),
          ],
        );
      },
    );
  }
}

class _CreateExerciseButton extends StatelessWidget {
  const _CreateExerciseButton({
    required this.primary,
    required this.onPressed,
    this.compact = false,
    this.expand = false,
  });

  final Color primary;
  final VoidCallback onPressed;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final label = compact ? 'Novo' : 'Novo exercício';
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(expand ? double.infinity : 0, 48),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
        foregroundColor: primary,
        side: BorderSide(color: primary.withValues(alpha: 0.42)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(Icons.add_rounded, color: primary, size: compact ? 20 : 21),
      label: Text(
        label,
        style: compact
            ? FocuxHubTypography.bodyMuted(
                color: primary,
                fontWeight: FontWeight.w900,
              )
            : FocuxHubTypography.cardTitle(color: primary).copyWith(
                fontWeight: FontWeight.w900,
              ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Criar exercício personalizado',
      child: Tooltip(
        message: 'Criar exercício personalizado',
        preferBelow: false,
        child:
            expand ? SizedBox(width: double.infinity, child: button) : button,
      ),
    );
  }
}
