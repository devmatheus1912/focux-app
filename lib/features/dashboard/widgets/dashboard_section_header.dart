import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../utils/dashboard_readability.dart';

/// Título de seção da Home + ação opcional (Ver todos / Relatório / Agenda).
class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final link = BrandPalette.sectionLink(primary, dark: isDark);
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
        if (showAction)
          Semantics(
            button: true,
            label: action,
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: link,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action),
            ),
          ),
      ],
    );
  }
}
