import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ferramentas/data/ferramentas_catalogo_models.dart';
import '../../ferramentas/providers/ferramentas_catalogo_provider.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_shortcut_navigation.dart';

/// Atalhos de crescimento no Perfil — mesma árvore do catálogo BFF quando
/// disponível; seed local só cobre rota/label se o item não vier no catalogo.
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

  static const _entries = <_ProfileToolEntry>[
    _ProfileToolEntry(
      icon: Icons.smart_toy_outlined,
      label: 'Automações',
      value: 'Fluxos',
      rotaApp: '/automacoes',
      featureGate: 'AUTOMACOES',
      legacyIds: ['automacoes'],
    ),
    _ProfileToolEntry(
      icon: Icons.storefront_outlined,
      label: 'Loja digital',
      value: 'Vitrine PIX',
      rotaApp: '/loja',
      featureGate: 'LOJA_DIGITAL',
      legacyIds: ['loja'],
    ),
    _ProfileToolEntry(
      icon: Icons.groups_outlined,
      label: 'Equipe',
      value: 'Assistentes',
      rotaApp: '/perfil/equipe',
      featureGate: 'EQUIPE_RBAC',
      legacyIds: ['equipe'],
    ),
    _ProfileToolEntry(
      icon: Icons.track_changes_outlined,
      label: 'Hábitos',
      value: 'Coaching diário',
      rotaApp: '/habitos',
      featureGate: 'HABIT_COACHING',
      legacyIds: ['habitos'],
    ),
    _ProfileToolEntry(
      icon: Icons.flag_outlined,
      label: 'Desafios',
      value: 'Campanhas',
      rotaApp: '/desafios',
      featureGate: 'COMUNIDADE_GRUPOS',
      legacyIds: ['desafios'],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(ref);
    final catalogo = ref.watch(ferramentasCatalogoProvider).valueOrNull;

    return Column(
      children: [
        for (var i = 0; i < _entries.length; i++)
          () {
            final entry = _entries[i];
            CatalogoEntrada? fromCatalog;
            if (catalogo != null) {
              for (final id in entry.legacyIds) {
                fromCatalog = catalogo.findByLegacyId(id);
                if (fromCatalog != null) break;
              }
            }
            final entrada =
                fromCatalog ??
                CatalogoEntrada(
                  id: entry.legacyIds.first,
                  titulo: entry.label,
                  rotaApp: entry.rotaApp,
                  featureGate: entry.featureGate,
                  unlocked: true,
                  legacyIds: entry.legacyIds,
                );
            final shortcut = DashboardToolShortcut.fromEntrada(entrada);
            final locked = !shortcut.isUnlocked(features);
            final tier = locked ? shortcut.tierBadgeLabel() : null;
            return tileBuilder(
              icon: entry.icon,
              label: entrada.titulo.isNotEmpty ? entrada.titulo : entry.label,
              value: locked ? 'Plano $tier' : entry.value,
              locked: locked,
              showDivider: i != _entries.length - 1,
              upgradeTierLabel: tier,
              onTap: () => openDashboardShortcut(context, ref, shortcut),
            );
          }(),
      ],
    );
  }
}

class _ProfileToolEntry {
  const _ProfileToolEntry({
    required this.icon,
    required this.label,
    required this.value,
    required this.rotaApp,
    required this.featureGate,
    required this.legacyIds,
  });

  final IconData icon;
  final String label;
  final String value;
  final String rotaApp;
  final String featureGate;
  final List<String> legacyIds;
}
