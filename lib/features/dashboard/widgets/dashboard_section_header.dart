import 'package:flutter/material.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../utils/dashboard_readability.dart';

/// Título de seção da Home + ação opcional (Ver todos / Relatório / Agenda).
class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Ação em ícone (ex.: ajuda) no lugar do link de texto.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final action = actionLabel?.trim();
    final showAction = action != null && action.isNotEmpty && onAction != null;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: FxSettingsLayout.sectionHeader(color: mute),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (showAction)
          FxActionLink(label: action, onTap: onAction),
      ],
    );
  }
}
