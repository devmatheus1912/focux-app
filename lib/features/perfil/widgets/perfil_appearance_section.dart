import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_readability.dart';

/// Aparência do app — só no Perfil. Padrão: modo do celular.
class PerfilAppearanceSection extends ConsumerWidget {
  const PerfilAppearanceSection({super.key, required this.isDark});

  final bool isDark;

  static const _options = <(ThemeMode, String)>[
    (ThemeMode.system, 'Sistema'),
    (ThemeMode.light, 'Claro'),
    (ThemeMode.dark, 'Escuro'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final caption = dashboardReadableCaption(context, isDark: isDark);
    final fill = isDark ? EagleTokens.darkCardHi : EagleTokens.lightCardHi;

    return DecoratedBox(
      decoration: fxStripCardDecoration(
        context,
        radius: TokensStrip.rCard,
        glowStrength: 0.03,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aparência',
              style: FocuxHubTypography.bodyMuted(
                color: heading,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mode == ThemeMode.system
                  ? 'Segue o claro ou escuro do celular.'
                  : 'Travado neste aparelho. Sistema volta a seguir o celular.',
              style: FocuxHubTypography.bodyMuted(
                color: caption,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(TokensStrip.rXl),
                border: Border.all(color: chrome.lineStrong),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    for (final option in _options)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: mode == option.$1,
                          label: 'Aparência: ${option.$2}',
                          child: Material(
                            color: fxTransparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(themeModeProvider.notifier)
                                    .setMode(option.$1);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color:
                                        mode == option.$1
                                            ? BrandPalette.soft(
                                              primary,
                                              dark: isDark,
                                            )
                                            : fxTransparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        mode == option.$1
                                            ? Border.all(
                                              color: primary.withValues(
                                                alpha: 0.42,
                                              ),
                                            )
                                            : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      option.$2,
                                      style: FocuxHubTypography.cardTitle(
                                        color:
                                            mode == option.$1
                                                ? primary
                                                : caption,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
