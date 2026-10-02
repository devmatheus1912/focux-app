import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../leads/providers/leads_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_a11y.dart';

/// Lista inset de atalhos — mesma pele do Perfil / catálogo completo.
class DashboardToolShortcutGroup extends ConsumerWidget {
  const DashboardToolShortcutGroup({
    super.key,
    required this.shortcuts,
    required this.onShortcut,
    this.header,
    this.caption,
    this.footer,
    this.homePlanoFeatures,
  });

  final List<DashboardToolShortcut> shortcuts;
  final String? header;
  final String? caption;
  final Widget? footer;
  final PlanoFeatures? homePlanoFeatures;
  final void Function(DashboardToolShortcut shortcut) onShortcut;

  static bool isLockedLeads(DashboardToolShortcut s, PlanoFeatures features) =>
      PlanoRecursoKeys.fromCapability(s.capability) == PlanoRecursoKeys.leads &&
      !s.isUnlocked(features);

  /// "N leads esperando" do Free. Só consulta a contagem com o CRM trancado.
  static String? watchLeadsTeaser(
    WidgetRef ref,
    Iterable<DashboardToolShortcut> shortcuts,
    PlanoFeatures features,
  ) {
    if (!shortcuts.any((s) => isLockedLeads(s, features))) return null;
    return leadsTeaserLabel(ref.watch(leadsContagemTeaserProvider).value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(
      ref,
      homeOverride: homePlanoFeatures,
    );
    final chrome = ShellChrome.of(context);
    final leadsTeaser = watchLeadsTeaser(ref, shortcuts, features);

    return FxSettingsGroup(
      header: header,
      caption: caption,
      footer: footer,
      children: [
        for (var i = 0; i < shortcuts.length; i++)
          FxSettingsTile(
            fxIcon: shortcuts[i].icon,
            label: shortcuts[i].label,
            subtitle:
                isLockedLeads(shortcuts[i], features) ? leadsTeaser : null,
            semanticsLabel: dashboardShortcutSemanticsLabel(shortcuts[i]),
            value:
                shortcuts[i].isUnlocked(features)
                    ? ''
                    : shortcuts[i].tierBadgeLabel(),
            locked: !shortcuts[i].isUnlocked(features),
            upgradeTierLabel: shortcuts[i].tierBadgeLabel(),
            mute: chrome.mute,
            line: chrome.line,
            showDivider: i < shortcuts.length - 1,
            onTap: () => onShortcut(shortcuts[i]),
          ),
      ],
    );
  }
}
