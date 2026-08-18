import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';

/// Ajuda contextual da lista de alunos (pilar 80).
Future<void> showAlunosListHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
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
                  'Lista de alunos',
                  style: FocuxHubTypography.pageTitle(ctx, color: ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Priorize contato, filtre por status e abra a ficha com um toque.',
                  style: FocuxHubTypography.bodyMuted(color: mute, height: 1.35),
                ),
                const SizedBox(height: 16),
                tip(
                  'Contato hoje',
                  'Alunos em risco, inadimplentes ou sem treino recente aparecem no topo e no banner.',
                ),
                tip(
                  'Filtros e busca',
                  'Use os chips para focar a base. A busca considera nome e objetivo.',
                ),
                tip(
                  'Lista compacta',
                  'Em Organizar lista, ative compacta para ver mais alunos na tela.',
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
