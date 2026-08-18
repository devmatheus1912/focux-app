import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';

Future<void> showTreinosListHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final chrome = ShellChrome.forDark(isDark);
      final ink = chrome.ink;
      final mute = chrome.mute;
      final primary = Theme.of(ctx).colorScheme.primary;

      Widget tip(String title, String body) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: FocuxHubTypography.sectionTitle(ctx, color: ink),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: FocuxHubTypography.bodyMuted(color: mute, height: 1.35),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: chrome.bottomSheet(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Biblioteca de treinos',
                  style: FocuxHubTypography.pageTitle(ctx, color: ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crie um plano base, abra com um toque e atribua quando precisar.',
                  style: FocuxHubTypography.bodyMuted(
                    color: mute,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                tip(
                  'Novo plano',
                  'O + no topo cria o treino. A biblioteca lista o que já está pronto.',
                ),
                tip(
                  'Ações',
                  'Toque no card para abrir. O menu do card atribui, copia ou remove.',
                ),
                tip(
                  'Seleção',
                  'Segure um card ou use o checklist. A busca some e as ações sobem para a barra de baixo.',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Entendi',
                      style: TextStyle(
                        color: BrandPalette.sectionLink(primary, dark: isDark),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
