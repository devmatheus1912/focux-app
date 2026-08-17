import 'package:flutter/material.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/design_tokens.dart';
import 'perfil_action_tile.dart';

/// Itens de Conta e segurança (conteúdo; o colapso fica no pai).
class PerfilContaSegurancaSection extends StatelessWidget {
  const PerfilContaSegurancaSection({
    super.key,
    required this.isDark,
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.line,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final bool isDark;
  final Color accent;
  final Color actionInk;
  final Color mute;
  final Color line;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PerfilActionTile(
          icon: Icons.description_outlined,
          label: 'Termos de uso',
          value: '',
          accent: accent,
          actionInk: actionInk,
          mute: mute,
          line: line,
          onTap: () => FocuxLegal.openTerms(),
        ),
        PerfilActionTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Política de privacidade',
          value: '',
          accent: accent,
          actionInk: actionInk,
          mute: mute,
          line: line,
          onTap: () => FocuxLegal.openPrivacy(),
        ),
        PerfilActionTile(
          icon: Icons.logout,
          label: 'Sair da conta',
          value: '',
          accent: EagleTokens.bad,
          mute: mute,
          line: line,
          danger: true,
          onTap: onLogout,
        ),
        PerfilActionTile(
          icon: Icons.delete_forever_outlined,
          label: 'Excluir minha conta',
          value: '',
          accent: EagleTokens.bad,
          mute: mute,
          line: line,
          danger: true,
          showDivider: false,
          onTap: onDeleteAccount,
        ),
      ],
    );
  }
}
