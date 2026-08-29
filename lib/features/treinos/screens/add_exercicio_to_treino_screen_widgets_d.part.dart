part of 'add_exercicio_to_treino_screen.dart';

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

class _BuscarQuickLinks extends StatelessWidget {
  const _BuscarQuickLinks({
    required this.totalCount,
    required this.createLabel,
    required this.primary,
    required this.onOpenPicker,
    required this.onCreate,
  });

  final int totalCount;
  final String createLabel;
  final Color primary;
  final VoidCallback onOpenPicker;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onOpenPicker,
          child: Text(
            'Biblioteca ($totalCount)',
            style: FocuxHubTypography.bodyMuted(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onCreate,
          child: Text(
            createLabel,
            style: FocuxHubTypography.bodyMuted(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
