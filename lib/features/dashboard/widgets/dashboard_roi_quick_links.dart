import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_screen_helpers.dart';
import '../utils/dashboard_shortcut_navigation.dart';

class DashboardRoiQuickLinksRow extends ConsumerWidget {
  const DashboardRoiQuickLinksRow({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final features = effectivePlanoFeatures(ref);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        4,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DashboardMicrocopy.retornoRapido,
            style: dashboardSectionKickerStyle(context, isDark: isDark),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final shortcut in DashboardToolShortcut.roiQuickLinks) ...[
                  DashboardRoiShortcutChip(
                    shortcut: shortcut,
                    isDark: isDark,
                    locked: !shortcut.isUnlocked(features),
                    tierLabel:
                        shortcut.isUnlocked(features)
                            ? null
                            : shortcut.tierBadgeLabel(),
                    linkColor: link,
                    onTap: () => openDashboardShortcut(context, ref, shortcut),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardRoiShortcutChip extends StatelessWidget {
  const DashboardRoiShortcutChip({
    super.key,
    required this.shortcut,
    required this.isDark,
    required this.locked,
    required this.onTap,
    required this.linkColor,
    this.tierLabel,
  });

  final DashboardToolShortcut shortcut;
  final bool isDark;
  final bool locked;
  final String? tierLabel;
  final Color linkColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg =
        locked
            ? BrandPalette.soft(primary, dark: isDark).withValues(alpha: 0.55)
            : BrandPalette.soft(primary, dark: isDark);
    final labelColor = locked ? linkColor.withValues(alpha: 0.78) : linkColor;

    return Semantics(
      button: true,
      label:
          locked
              ? '${shortcut.label}, trancado. Plano ${tierLabel ?? shortcut.tierBadgeLabel()}'
              : shortcut.label,
      child: ActionChip(
        avatar:
            locked
                ? Icon(Icons.lock_rounded, size: 14, color: labelColor)
                : null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shortcut.label, maxLines: 1, softWrap: false),
            if (locked && tierLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tierLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        onPressed: onTap,
        backgroundColor: bg,
        side:
            locked
                ? BorderSide(color: labelColor.withValues(alpha: 0.22))
                : BorderSide.none,
        labelStyle: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
