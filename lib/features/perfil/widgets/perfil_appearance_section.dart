import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/theme/fx_icons.dart';

/// Preferências: "Aparência · Claro" numa linha, que abre a escolha.
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
    final chrome = ShellChrome.forBrightness(context, isDark);
    return FxSettingsGroup(
      header: 'Preferências',
      children: [
        FxSettingsTile(
          icon: FxIcons.sono,
          label: 'Aparência',
          value: labelFor(mode),
          mute: chrome.mute,
          line: chrome.line,
          picker: true,
          showDivider: false,
          onTap: () async {
            final escolha = await showFxInsetPickerSheet<ThemeMode>(
              context,
              title: 'Aparência',
              selected: mode,
              items: [
                for (final option in _options)
                  FxInsetPickerSheetItem(value: option.$1, label: option.$2),
              ],
            );
            if (escolha != null) {
              ref.read(themeModeProvider.notifier).setMode(escolha);
            }
          },
        ),
      ],
    );
  }
}
