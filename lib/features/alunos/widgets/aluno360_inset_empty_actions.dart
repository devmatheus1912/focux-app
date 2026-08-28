import 'package:flutter/material.dart';

import '../../../core/widgets/fx_settings_tile.dart';

/// Ações de empty state dentro de [FxSettingsGroup] — paridade inset Perfil.
class Aluno360InsetEmptyActionSpec {
  const Aluno360InsetEmptyActionSpec({
    this.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.highlight = false,
    this.accent,
  });

  final Key? key;
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool highlight;
  final Color? accent;
}

List<Widget> aluno360InsetEmptyActionTiles(
  List<Aluno360InsetEmptyActionSpec> actions,
) {
  return [
    for (var i = 0; i < actions.length; i++)
      FxSettingsTile(
        key: actions[i].key,
        icon: actions[i].icon,
        accent: actions[i].accent,
        label: actions[i].label,
        subtitle: actions[i].subtitle,
        value: '',
        highlight: actions[i].highlight,
        showDivider: i < actions.length - 1,
        onTap: actions[i].onTap,
      ),
  ];
}
