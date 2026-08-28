import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_settings_tile.dart';

/// Itens de Operação do hub Perfil.
class PerfilOperacaoSection extends StatelessWidget {
  const PerfilOperacaoSection({
    super.key,
    required this.accent,
    required this.mute,
    required this.line,
    required this.pixDone,
    required this.planoLabel,
  });

  final Color accent;
  final Color mute;
  final Color line;
  final bool pixDone;
  final String planoLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FxSettingsTile(
          icon: Icons.workspace_premium_outlined,
          label: 'Planos e assinatura',
          value: planoLabel,
          accent: accent,
          mute: mute,
          line: line,
          onTap: () => context.push('/assinatura'),
        ),
        FxSettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Carteira e PIX',
          value: pixDone ? 'Completa' : 'Configurar',
          mute: mute,
          line: line,
          onTap: () => context.push('/perfil/wallet'),
        ),
        FxSettingsTile(
          icon: Icons.bolt_outlined,
          label: 'Migração Focux',
          value: 'Importar com IA',
          mute: mute,
          line: line,
          onTap: () => context.push('/migracao-magica'),
        ),
        FxSettingsTile(
          icon: Icons.apps_outlined,
          label: 'Mais ferramentas',
          value: 'Crescimento e loja',
          mute: mute,
          line: line,
          showDivider: false,
          onTap: () => context.push('/perfil/ferramentas'),
        ),
      ],
    );
  }
}
