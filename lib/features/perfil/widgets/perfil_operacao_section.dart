import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'perfil_action_tile.dart';

/// Itens de Operação do hub Perfil (conteúdo; o colapso fica no pai).
class PerfilOperacaoSection extends StatelessWidget {
  const PerfilOperacaoSection({
    super.key,
    required this.isDark,
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.line,
    required this.pixDone,
  });

  final bool isDark;
  final Color accent;
  final Color actionInk;
  final Color mute;
  final Color line;
  final bool pixDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PerfilActionTile(
          icon: Icons.workspace_premium_outlined,
          label: 'Planos e assinatura',
          value: 'Gerenciar',
          accent: accent,
          actionInk: actionInk,
          mute: mute,
          line: line,
          onTap: () => context.push('/assinatura'),
        ),
        PerfilActionTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Carteira e PIX',
          value: pixDone ? 'Completa' : 'Configurar',
          accent: accent,
          actionInk: actionInk,
          mute: mute,
          line: line,
          onTap: () => context.push('/perfil/wallet'),
        ),
        PerfilActionTile(
          icon: Icons.bolt_outlined,
          label: 'Migração Focux',
          value: 'Importar com IA',
          accent: accent,
          actionInk: actionInk,
          mute: mute,
          line: line,
          onTap: () => context.push('/migracao-magica'),
        ),
        PerfilActionTile(
          icon: Icons.apps_outlined,
          label: 'Mais ferramentas',
          value: 'Crescimento e loja',
          accent: accent,
          actionInk: actionInk,
          mute: mute,
          line: line,
          showDivider: false,
          onTap: () => context.push('/perfil/ferramentas'),
        ),
      ],
    );
  }
}
