import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
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
    final chrome = ShellChrome.forBrightness(context, isDark);
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
    final picked = await showFxInsetPickerSheet<ThemeMode>(
      context,
      title: 'Aparência',
      headerIcon: Icons.dark_mode_outlined,
      selected: current,
      items: [
        for (final option in _options)
          FxInsetPickerSheetItem(
            value: option.$1,
            label: option.$2,
          ),
      ],
    );
    if (picked == null) return;
    ref.read(themeModeProvider.notifier).setMode(picked);
  }
}
