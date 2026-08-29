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
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final tabMotionMs = fxMotionDurationMs(context, normal: 160);

    return Semantics(
      container: true,
      label: 'Como adicionar: buscar ou explorar',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          border: Border.all(
            color: line.withValues(alpha: isDark ? 0.7 : 0.85),
          ),
          color: isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
        ),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    width: 1,
                    thickness: FxSettingsLayout.dividerThickness,
                    color: line.withValues(alpha: isDark ? 0.55 : 0.7),
                  ),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: selectedIndex == i,
                    label: _tabs[i].semantics,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onChanged(i),
                        borderRadius: BorderRadius.horizontal(
                          left:
                              i == 0
                                  ? Radius.circular(TokensStrip.rSm - 1)
                                  : Radius.zero,
                          right:
                              i == _tabs.length - 1
                                  ? Radius.circular(TokensStrip.rSm - 1)
                                  : Radius.zero,
                        ),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: tabMotionMs),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.center,
                          color:
                              selectedIndex == i
                                  ? action.withValues(
                                    alpha: isDark ? 0.18 : 0.10,
                                  )
                                  : Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _tabs[i].icon,
                                size: 17,
                                color:
                                    selectedIndex == i ? action : mute,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _tabs[i].label,
                                style: FocuxHubTypography.chip(
                                  selectedIndex == i ? action : ink,
                                ).copyWith(
                                  fontSize: 12,
                                  fontWeight:
                                      selectedIndex == i
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
    return FxSettingsGroup(
      accent: primary,
      children: [
        FxSettingsTile(
          icon: Icons.library_books_outlined,
          accent: primary,
          label: 'Biblioteca completa',
          subtitle: '$totalCount exercícios',
          value: '',
          onTap: onOpenPicker,
        ),
        FxSettingsTile(
          icon: Icons.add_rounded,
          accent: primary,
          label: createLabel,
          value: '',
          showDivider: false,
          onTap: onCreate,
        ),
      ],
    );
  }
}

class _BuscarIdleHint extends StatelessWidget {
  const _BuscarIdleHint({
    required this.primary,
    required this.isDark,
  });

  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      label: 'Digite para buscar exercícios ou use os atalhos abaixo',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(
              Icons.search_rounded,
              size: 36,
              color: primary.withValues(alpha: isDark ? 0.42 : 0.28),
            ),
            const SizedBox(height: 10),
            Text(
              'Busque por nome',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.cardTitle(color: mute).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ou abra a biblioteca e os filtros abaixo',
              textAlign: TextAlign.center,
              style: FxSettingsLayout.footer(color: mute),
            ),
          ],
        ),
      ),
    );
  }
}
