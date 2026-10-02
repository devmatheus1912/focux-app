import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_settings_tile.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/utils/plan_gate.dart';

/// Itens de Operação do hub Perfil.
class PerfilOperacaoSection extends ConsumerWidget {
  const PerfilOperacaoSection({
    super.key,
    required this.mute,
    required this.line,
    required this.pixDone,
    required this.planoLabel,
  });

  final Color mute;
  final Color line;
  final bool pixDone;
  final String planoLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carteira = PlanGate.watch(ref, PlanoRecursoKeys.carteira);
    return Column(
      children: [
        FxSettingsTile(
          icon: Icons.workspace_premium_outlined,
          label: 'Planos e assinatura',
          value: planoLabel,
          mute: mute,
          line: line,
          onTap: () => context.push('/assinatura'),
        ),
        FxSettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Carteira e PIX',
          value:
              !carteira.liberado
                  ? ''
                  : pixDone
                  ? 'Completa'
                  : 'Configurar',
          mute: mute,
          line: line,
          locked: !carteira.liberado,
          upgradeTierLabel: PlanGate.tierLabel(carteira.planoMinimo),
          onTap: PlanGate.tap(
            context,
            ref,
            PlanoRecursoKeys.carteira,
            featureName: 'Carteira e PIX',
            source: 'perfil_carteira',
            action: () => context.push('/perfil/wallet'),
          ),
        ),
        FxSettingsTile(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Convites',
          value: 'Link de cadastro',
          mute: mute,
          line: line,
          showDivider: false,
          onTap: () => context.push('/convites'),
        ),
      ],
    );
  }
}
