import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';

/// Aparência — linha iOS/ChatGPT com valor à direita e picker.
class PerfilAppearanceSection extends ConsumerWidget {
  const PerfilAppearanceSection({super.key, required this.isDark});

  final bool isDark;

  static const _options = <(ThemeMode, String)>[
    (ThemeMode.system, 'Sistema'),
    (ThemeMode.light, 'Claro'),
    (ThemeMode.dark, 'Escuro'),
  ];

  static String labelFor(ThemeMode mode) {
    for (final option in _options) {
      if (option.$1 == mode) return option.$2;
    }
    return 'Sistema';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final chrome = ShellChrome.forDark(isDark);
    final mute = chrome.mute;
    final line = chrome.line;

    return FxSettingsGroup(
      header: 'Tema',
      caption:
          mode == ThemeMode.system
              ? 'Segue o claro ou escuro do celular.'
              : 'Travado neste aparelho. Sistema volta a seguir o celular.',
      children: [
        FxSettingsTile(
          icon: Icons.dark_mode_outlined,
          label: 'Aparência',
          value: labelFor(mode),
          mute: mute,
          line: line,
          picker: true,
          showDivider: false,
          onTap: () => _openPicker(context, ref, mode),
        ),
      ],
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final chrome = ShellChrome.forDark(dark);
        final ink = chrome.ink;
        return FxHomeSheetSurface(
          isDark: dark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxHomeSheetHandle(isDark: dark),
              FxHomeSheetHeader(
                leading: Icon(
                  Icons.dark_mode_outlined,
                  color: BrandPalette.softened(
                    Theme.of(ctx).colorScheme.primary,
                  ),
                ),
                title: 'Aparência',
                isDark: dark,
              ),
              for (final option in _options)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setMode(option.$1);
                    Navigator.of(ctx).pop();
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: FxSettingsLayout.rowMinHeight,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.$2,
                            style: FxSettingsLayout.rowLabel(color: ink),
                          ),
                        ),
                        if (current == option.$1)
                          Icon(
                            Icons.check,
                            color: Theme.of(ctx).colorScheme.primary,
                            size: FxSettingsLayout.iconSize,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
