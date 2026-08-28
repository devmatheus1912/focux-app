part of 'create_treino_screen.dart';

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
