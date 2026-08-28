part of 'create_treino_screen.dart';

class _PlanoBaseSummary extends StatelessWidget {
  const _PlanoBaseSummary({
    required this.title,
    required this.meta,
    required this.primary,
    required this.soft,
    required this.onTap,
  });

  final String title;
  final String meta;
  final Color primary;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '$title. $meta. Toque para editar o nome',
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: soft,
                      size: FxSettingsLayout.iconSize,
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FxSettingsLayout.rowLabel(color: ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FxSettingsLayout.subhead(color: mute),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: mute,
                    size: FxSettingsLayout.chevronSize,
                  ),
                ],
              ),
            ),
          ),
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

Future<void> showCreateTreinoNivelPicker(
  BuildContext context, {
  required String? selected,
  required ValueChanged<String> onSelected,
}) {
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      final chrome = ShellChrome.forDark(dark);
      final ink = chrome.ink;
      final primary = Theme.of(ctx).colorScheme.primary;
      final soft = BrandPalette.softened(primary);

      return FxHomeSheetSurface(
        isDark: dark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FxHomeSheetHandle(isDark: dark),
            FxHomeSheetHeader(
              leading: Icon(Icons.tune_rounded, color: soft),
              title: 'Nível do plano',
              isDark: dark,
            ),
            for (var i = 0; i < CreateTreinoLogic.niveis.length; i++)
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(CreateTreinoLogic.niveis[i]);
                  Navigator.of(ctx).pop();
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: FxSettingsLayout.rowMinHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CreateTreinoLogic.niveisIcon[i],
                          color: soft,
                          size: FxSettingsLayout.iconSize,
                        ),
                        const SizedBox(width: TokensStrip.s3),
                        Expanded(
                          child: Text(
                            CreateTreinoLogic.niveisLabel[i],
                            style: FxSettingsLayout.rowLabel(color: ink),
                          ),
                        ),
                        if (selected == CreateTreinoLogic.niveis[i])
                          Icon(
                            Icons.check,
                            color: primary,
                            size: FxSettingsLayout.iconSize,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: TokensStrip.s2),
          ],
        ),
      );
    },
  );
}
