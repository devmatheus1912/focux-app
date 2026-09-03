import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/treinos_layout.dart';
import 'treino_home_sheet.dart';

/// Ação inset para sheets de treino — paridade Perfil / [FxSettingsTile].
class TreinoInsetActionSpec {
  const TreinoInsetActionSpec({
    required this.icon,
    required this.label,
    this.subtitle,
    this.showChevron = false,
    this.danger = false,
    this.highlight = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool showChevron;
  final bool danger;
  final bool highlight;
  final VoidCallback onTap;
}

List<Widget> treinoInsetActionTiles({
  required List<TreinoInsetActionSpec> actions,
  Color? accent,
}) {
  return [
    for (var i = 0; i < actions.length; i++)
      FxSettingsTile(
        icon: actions[i].icon,
        accent: accent,
        label: actions[i].label,
        subtitle: actions[i].subtitle,
        value: '',
        danger: actions[i].danger,
        highlight: actions[i].highlight,
        picker: actions[i].showChevron,
        showDivider: i < actions.length - 1,
        onTap: actions[i].onTap,
      ),
  ];
}

/// Menu de ações inset — [FxHomeSheetHeader] + [FxSettingsGroup].
class TreinoInsetActionSheet extends StatelessWidget {
  const TreinoInsetActionSheet({
    super.key,
    required this.isDark,
    required this.headerIcon,
    required this.title,
    this.subtitle,
    required this.actions,
    this.accent,
    this.maxHeight,
  });

  final bool isDark;
  final IconData headerIcon;
  final String title;
  final String? subtitle;
  final List<TreinoInsetActionSpec> actions;
  final Color? accent;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final primary = accent ?? Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final group = FxSettingsGroup(
      accent: primary,
      children: treinoInsetActionTiles(actions: actions, accent: soft),
    );

    return TreinoHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            subtitle: subtitle,
            leading: Icon(
              headerIcon,
              color: soft,
              size: FxSettingsLayout.iconSize,
            ),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          group,
        ],
      ),
    );
  }
}

/// Confirmação destrutiva inset — ação perigosa em grupo separado (Perfil).
class TreinoInsetConfirmSheet extends StatelessWidget {
  const TreinoInsetConfirmSheet({
    super.key,
    required this.isDark,
    required this.headerIcon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.accent,
  });

  final bool isDark;
  final IconData headerIcon;
  final String title;
  final String message;
  final String confirmLabel;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);

    return TreinoHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            subtitle: message,
            leading: Icon(
              headerIcon,
              color: EagleTokens.bad,
              size: FxSettingsLayout.iconSize,
            ),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EagleTokens.bad,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ),
          const SizedBox(height: FxSettingsLayout.footerAfterGroup),
          Center(
            child: Semantics(
              button: true,
              label: 'Cancelar',
              child: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: mute,
                  minimumSize: const Size(
                    TreinosLayout.touchTarget,
                    TreinosLayout.touchTarget,
                  ),
                  textStyle: FxSettingsLayout.footer(color: mute),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
