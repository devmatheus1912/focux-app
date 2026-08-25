import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../planos/data/planos_repository.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_shortcut_navigation.dart';

/// Atalhos de crescimento no Perfil — respeitam o plano ativo.
class GatedProfileShortcuts extends ConsumerWidget {
  const GatedProfileShortcuts({super.key, required this.tileBuilder});

  /// Builder para reutilizar tiles do perfil sem acoplamento circular.
  final Widget Function({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool locked,
    required bool showDivider,
    String? upgradeTierLabel,
  })
  tileBuilder;

  static const _entries = [
    (Icons.smart_toy_outlined, 'Automações', 'Fluxos', 'Automações'),
    (Icons.emoji_events_outlined, 'Desafios', 'Comunidade', 'Desafios'),
    (Icons.storefront_outlined, 'Loja digital', 'Vitrine PIX', 'Loja'),
    (Icons.groups_outlined, 'Equipe', 'Assistentes', 'Equipe'),
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
        for (var i = 0; i < _entries.length; i++)
          _tileFor(
            context,
            ref,
            features,
            _entries[i],
            showDivider: i != _entries.length - 1,
          ),
      ],
    );
  }

  Widget _tileFor(
    BuildContext context,
    WidgetRef ref,
    PlanoFeatures features,
    (IconData, String, String, String) entry, {
    required bool showDivider,
  }) {
    final shortcut = _shortcutFor(entry.$4);
    if (shortcut == null) {
      return tileBuilder(
        icon: entry.$1,
        label: entry.$2,
        value: entry.$3,
        locked: false,
        showDivider: showDivider,
        upgradeTierLabel: null,
        onTap: () {},
      );
    }
    final locked = !shortcut.isUnlocked(features);
    final tier = locked ? shortcut.tierBadgeLabel() : null;
    final value = locked ? 'Plano $tier' : entry.$3;

    return tileBuilder(
      icon: entry.$1,
      label: entry.$2,
      value: value,
      locked: locked,
      showDivider: showDivider,
      upgradeTierLabel: tier,
      onTap: () => openDashboardShortcut(context, ref, shortcut),
    );
  }
}
