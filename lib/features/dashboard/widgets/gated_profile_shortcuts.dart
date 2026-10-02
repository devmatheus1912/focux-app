import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/utils/plan_gate.dart';

/// Atalhos de crescimento no Perfil — trava pelo `recursos` do plano.
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
      recurso: PlanoRecursoKeys.automacoes,
    ),
    _ProfileToolEntry(
      icon: Icons.storefront_outlined,
      label: 'Loja digital',
      value: 'Vitrine PIX',
      rotaApp: '/loja',
      recurso: PlanoRecursoKeys.loja,
    ),
    _ProfileToolEntry(
      icon: Icons.groups_outlined,
      label: 'Equipe',
      value: 'Em breve',
      rotaApp: '/perfil/equipe',
      recurso: PlanoRecursoKeys.equipe,
    ),
    _ProfileToolEntry(
      icon: Icons.track_changes_outlined,
      label: 'Hábitos',
      value: 'Coaching diário',
      rotaApp: '/habitos',
      recurso: PlanoRecursoKeys.habitos,
    ),
    _ProfileToolEntry(
      icon: Icons.flag_outlined,
      label: 'Desafios',
      value: 'Campanhas',
      rotaApp: '/desafios',
      recurso: PlanoRecursoKeys.desafios,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (var i = 0; i < _seed.length; i++)
          () {
            final entry = _seed[i];
            final recurso = PlanGate.watch(ref, entry.recurso);
            final tier = PlanGate.tierLabel(recurso.planoMinimo);
            return tileBuilder(
              icon: entry.icon,
              label: entry.label,
              value: recurso.liberado ? entry.value : 'Plano $tier',
              locked: !recurso.liberado,
              showDivider: i != _seed.length - 1,
              upgradeTierLabel: recurso.liberado ? null : tier,
              onTap: PlanGate.tap(
                context,
                ref,
                entry.recurso,
                featureName: entry.label,
                source: 'perfil_ferramentas',
                action: () {
                  AnalyticsService.instance.track(
                    'dashboard_shortcut_open',
                    props: {
                      'label': entry.label,
                      'route': entry.rotaApp,
                      'source': 'perfil_ferramentas',
                    },
                  );
                  context.push(entry.rotaApp);
                },
              ),
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
    required this.recurso,
  });

  final IconData icon;
  final String label;
  final String value;
  final String rotaApp;
  final String recurso;
}
