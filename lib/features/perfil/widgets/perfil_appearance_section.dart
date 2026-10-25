import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_settings_group.dart';

/// Preferências — Aparência com as três opções à vista (sem abrir sheet).
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
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensStrip.s3,
            vertical: TokensStrip.s3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dark_mode_outlined,
                    size: FxSettingsLayout.iconSize,
                    color: chrome.mute,
                  ),
                  const SizedBox(width: FxSettingsLayout.iconGap),
                  Text(
                    'Aparência',
                    style: FxSettingsLayout.rowLabel(color: chrome.ink),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
              FxChoiceStrip<ThemeMode>(
                quebrar: true,
                itens: [
                  for (final option in _options)
                    FxChoiceItem(value: option.$1, label: option.$2),
                ],
                selecionado: mode,
                onSelecionar: (picked) =>
                    ref.read(themeModeProvider.notifier).setMode(picked),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
