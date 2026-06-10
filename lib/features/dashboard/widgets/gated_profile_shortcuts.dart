import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_shortcut_navigation.dart';

/// Atalhos de crescimento no Perfil — respeitam o plano ativo.
class GatedProfileShortcuts extends ConsumerWidget {
  const GatedProfileShortcuts({
    super.key,
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.line,
    required this.tileBuilder,
  });

  final Color accent;
  final Color actionInk;
  final Color mute;
  final Color line;

  /// Builder para reutilizar [_ActionTile] do perfil sem acoplamento circular.
  final Widget Function({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool locked,
    String? upgradeTierLabel,
  })
  tileBuilder;

  static const _entries = [
    (Icons.smart_toy_outlined, 'Automações', 'Fluxos', 'Automações'),
    (Icons.emoji_events_outlined, 'Desafios', 'Comunidade', 'Desafios'),
    (Icons.storefront_outlined, 'Loja digital', 'Vitrine PIX', 'Loja'),
    (Icons.groups_outlined, 'Equipe', 'Assistentes e RBAC', 'Equipe'),
    (Icons.track_changes_outlined, 'Hábitos', 'Coaching diário', 'Hábitos'),
  ];

  DashboardToolShortcut? _shortcutFor(String label) {
    for (final s in DashboardToolShortcut.moreTools) {
      if (s.label == label) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(ref);

    return Column(
      children: [
        for (final entry in _entries) ...[
          Builder(
            builder: (context) {
              final shortcut = _shortcutFor(entry.$4);
              final locked = shortcut != null && !shortcut.isUnlocked(features);
              final tier = locked ? shortcut.tierBadgeLabel() : null;
              final value = locked ? 'Plano $tier' : entry.$3;

              return tileBuilder(
                icon: entry.$1,
                label: entry.$2,
                value: value,
                locked: locked,
                upgradeTierLabel: tier,
                onTap: () {
                  if (shortcut != null) {
                    openDashboardShortcut(context, ref, shortcut);
                  }
                },
              );
            },
          ),
        ],
      ],
    );
  }
}
