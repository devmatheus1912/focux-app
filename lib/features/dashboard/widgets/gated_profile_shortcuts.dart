import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ferramentas/data/ferramentas_catalogo_models.dart';
import '../../ferramentas/providers/ferramentas_catalogo_provider.dart';
import '../../ferramentas/utils/ferramentas_icons.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_shortcut_navigation.dart';

/// Atalhos de crescimento no Perfil — espelha o catálogo (atalhosHome + seed).
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

  static const _seed = <_ProfileToolEntry>[
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
    _ProfileToolEntry(
      icon: Icons.campaign_outlined,
      label: 'Broadcast',
      value: 'Base inteira',
      rotaApp: '/broadcasts',
      featureGate: 'BROADCAST',
      legacyIds: ['broadcast', 'broadcasts'],
    ),
    _ProfileToolEntry(
      icon: Icons.person_search_outlined,
      label: 'Leads',
      value: 'Captura',
      rotaApp: '/leads',
      featureGate: 'LEADS',
      legacyIds: ['leads'],
    ),
    _ProfileToolEntry(
      icon: Icons.favorite_outline,
      label: 'Saúde da base',
      value: 'Retenção',
      rotaApp: '/retencao',
      featureGate: 'RETENCAO',
      legacyIds: ['recuperacao', 'retencao'],
    ),
    _ProfileToolEntry(
      icon: Icons.receipt_long_outlined,
      label: 'Cobrança auto',
      value: 'Dunning',
      rotaApp: '/dunning',
      featureGate: 'FINANCEIRO',
      legacyIds: ['cobranca-auto', 'dunning'],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(ref);
    final catalogo = ref.watch(ferramentasCatalogoProvider).valueOrNull;

    final resolved = <({CatalogoEntrada entrada, IconData icon, String value})>[];
    final seen = <String>{};

    void addEntrada(CatalogoEntrada entrada, {IconData? icon, String? value}) {
      final key = (entrada.rotaApp ?? entrada.id).trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) return;
      if ((entrada.rotaApp ?? '').trim().isEmpty) return;
      resolved.add((
        entrada: entrada,
        icon: icon ?? _iconFor(entrada),
        value: value ?? (entrada.papel ?? 'Ferramenta'),
      ));
    }

    if (catalogo != null) {
      for (final atalho in catalogo.atalhosHome) {
        addEntrada(atalho);
      }
      for (final entry in _seed) {
        CatalogoEntrada? fromCatalog;
        for (final id in entry.legacyIds) {
          fromCatalog = catalogo.findByLegacyId(id);
          if (fromCatalog != null) break;
        }
        addEntrada(
          fromCatalog ??
              CatalogoEntrada(
                id: entry.legacyIds.first,
                titulo: entry.label,
                rotaApp: entry.rotaApp,
                featureGate: entry.featureGate,
                unlocked: true,
                legacyIds: entry.legacyIds,
              ),
          icon: entry.icon,
          value: entry.value,
        );
      }
    } else {
      for (final entry in _seed) {
        addEntrada(
          CatalogoEntrada(
            id: entry.legacyIds.first,
            titulo: entry.label,
            rotaApp: entry.rotaApp,
            featureGate: entry.featureGate,
            unlocked: true,
            legacyIds: entry.legacyIds,
          ),
          icon: entry.icon,
          value: entry.value,
        );
      }
    }

    return Column(
      children: [
        for (var i = 0; i < resolved.length; i++)
          () {
            final item = resolved[i];
            final shortcut = DashboardToolShortcut.fromEntrada(item.entrada);
            final locked = !shortcut.isUnlocked(features);
            final tier = locked ? shortcut.tierBadgeLabel() : null;
            return tileBuilder(
              icon: item.icon,
              label:
                  item.entrada.titulo.isNotEmpty
                      ? item.entrada.titulo
                      : item.entrada.id,
              value: locked ? 'Plano $tier' : item.value,
              locked: locked,
              showDivider: i != resolved.length - 1,
              upgradeTierLabel: tier,
              onTap: () => openDashboardShortcut(context, ref, shortcut),
            );
          }(),
      ],
    );
  }

  static IconData _iconFor(CatalogoEntrada entrada) {
    final name = ferramentasIconFor(entrada);
    return switch (name) {
      'robot' || 'bot' || 'spark' => Icons.smart_toy_outlined,
      'store' || 'shop' => Icons.storefront_outlined,
      'users' || 'team' => Icons.groups_outlined,
      'target' || 'habit' => Icons.track_changes_outlined,
      'flag' => Icons.flag_outlined,
      'megaphone' || 'broadcast' => Icons.campaign_outlined,
      'user-search' || 'leads' => Icons.person_search_outlined,
      'heart' => Icons.favorite_outline,
      'receipt' || 'coin' => Icons.receipt_long_outlined,
      _ => Icons.extension_outlined,
    };
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
