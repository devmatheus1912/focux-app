import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'treino_home_sheet.dart';
import '../../../core/widgets/fx_tonal_button.dart';

/// Ação inset para sheets de treino — paridade Perfil / [FxSettingsTile].
class TreinoInsetActionSpec {
  const TreinoInsetActionSpec({
    required this.icon,
    required this.label,
    this.subtitle,
    this.showChevron = false,
    this.danger = false,
    this.highlight = false,
    this.grupo,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool showChevron;
  final bool danger;
  final bool highlight;

  /// Título pequeno do grupo ("Montar", "Usar"). Ações seguidas com o mesmo
  /// título ficam no mesmo cartão.
  final String? grupo;
  final VoidCallback onTap;
}

List<Widget> treinoInsetActionChildren({
  required List<TreinoInsetActionSpec> actions,
  Color? accent,
}) {
  final safe = [
    for (final a in actions)
      if (!a.danger) a,
  ];
  final dangers = [
    for (final a in actions)
      if (a.danger) a,
  ];

  // Agrupa ações consecutivas com o mesmo título.
  final grupos = <(String?, List<TreinoInsetActionSpec>)>[];
  for (final a in safe) {
    if (grupos.isNotEmpty && grupos.last.$1 == a.grupo) {
      grupos.last.$2.add(a);
    } else {
      grupos.add((a.grupo, [a]));
    }
  }

  return [
    for (final (i, g) in grupos.indexed) ...[
      if (i > 0) const SizedBox(height: FxSettingsLayout.groupGap),
      if (g.$1 != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Semantics(
            header: true,
            child: Builder(
              builder: (context) => Text(
                g.$1!,
                style: FocuxHubTypography.chip(fxScreenMute(context)),
              ),
            ),
          ),
        ),
      FxSettingsGroup(
        accent: accent,
        children: [
          for (var j = 0; j < g.$2.length; j++)
            FxSettingsTile(
              icon: g.$2[j].icon,
              accent: accent,
              label: g.$2[j].label,
              subtitle: g.$2[j].subtitle,
              value: '',
              highlight: g.$2[j].highlight,
              // Chevron só em push de rota (Abrir). Comandos: picker esconde seta.
              picker: !g.$2[j].showChevron,
              showDivider: j < g.$2.length - 1,
              onTap: g.$2[j].onTap,
            ),
        ],
      ),
    ],
    // Destrutiva: linha de texto vermelha em cartão próprio, nunca botão cheio.
    if (dangers.isNotEmpty) ...[
      const SizedBox(height: FxSettingsLayout.groupGap),
      FxSettingsGroup(
        children: [
          for (var j = 0; j < dangers.length; j++)
            FxSettingsTile(
              icon: dangers[j].icon,
              label: dangers[j].label,
              value: '',
              danger: true,
              showDivider: j < dangers.length - 1,
              onTap: dangers[j].onTap,
            ),
        ],
      ),
    ],
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
    final groupChildren = treinoInsetActionChildren(
      actions: actions,
      accent: soft,
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
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: groupChildren,
              ),
            ),
          ),
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
              child: FxTonalButton(label: 'Cancelar', onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop(false);
                }, compact: true),
            ),
          ),
        ],
      ),
    );
  }
}
