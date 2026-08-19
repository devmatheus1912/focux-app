import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

Future<void> showTreinoDetailHelpSheet(BuildContext context) {
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
          decoration: fxStripCardDecoration(
            ctx,
            radius: 28,
            glowStrength: isDark ? 0.10 : 0.16,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Como montar este treino',
                  style: FocuxHubTypography.pageTitle(ctx, color: ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Adicione exercícios, ajuste a prescrição e atribua quando o plano estiver pronto.',
                  style: FocuxHubTypography.bodyMuted(
                    color: mute,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                tip(
                  'Adicionar',
                  'O botão principal inclui um exercício da biblioteca. O menu do topo também chega lá.',
                ),
                tip(
                  'Prescrição',
                  'Toque no exercício para séries, reps, carga e observações.',
                ),
                tip(
                  'Reordenar',
                  'Segure o card e arraste. A ordem é salva neste treino.',
                ),
                tip(
                  'Ações',
                  'O menu do exercício duplica, substitui ou remove. O menu do treino atribui ou exclui o plano.',
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
