import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ferramentas/providers/ferramentas_catalogo_provider.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_shortcut_navigation.dart';

/// Atalhos de crescimento no Perfil — respeitam o plano ativo e o BFF.
class GatedProfileShortcuts extends ConsumerWidget {
  const GatedProfileShortcuts({super.key, required this.tileBuilder});

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
    (Icons.smart_toy_outlined, 'Automações', 'Fluxos', 'automacoes'),
    (Icons.emoji_events_outlined, 'Desafios', 'Comunidade', 'desafios'),
    (Icons.storefront_outlined, 'Loja digital', 'Vitrine PIX', 'loja'),
    (Icons.groups_outlined, 'Equipe', 'Assistentes', 'equipe'),
    (Icons.track_changes_outlined, 'Hábitos', 'Coaching diário', 'habitos'),
  ];

  DashboardToolShortcut? _shortcutFor(
    Iterable<DashboardToolShortcut> leaves,
    String legacyOrId,
  ) {
    final needle = legacyOrId.toLowerCase();
    for (final s in leaves) {
      if (s.entrada.id.toLowerCase() == needle) return s;
      if (s.entrada.legacyIds.any((id) => id.toLowerCase() == needle)) {
        return s;
      }
      final titulo = s.label.toLowerCase();
      if (titulo == needle || titulo.contains(needle)) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(ref);
    final catalogo = ref.watch(ferramentasCatalogoProvider).valueOrNull;
    if (catalogo == null) return const SizedBox.shrink();
    final leaves = [
      for (final hub in catalogo.hubs) ...catalogLeavesFromHub(hub),
    ];

    final matched = <(IconData, String, String, DashboardToolShortcut)>[];
    for (final entry in _entries) {
      final shortcut = _shortcutFor(leaves, entry.$4);
      if (shortcut == null) continue;
      matched.add((entry.$1, entry.$2, entry.$3, shortcut));
    }
    if (matched.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < matched.length; i++)
          tileBuilder(
            icon: matched[i].$1,
            label: matched[i].$2,
            value:
                matched[i].$4.isUnlocked(features)
                    ? matched[i].$3
                    : 'Plano ${matched[i].$4.tierBadgeLabel()}',
            locked: !matched[i].$4.isUnlocked(features),
            showDivider: i != matched.length - 1,
            upgradeTierLabel:
                matched[i].$4.isUnlocked(features)
                    ? null
                    : matched[i].$4.tierBadgeLabel(),
            onTap:
                () => openDashboardShortcut(context, ref, matched[i].$4),
          ),
      ],
    );
  }
}
