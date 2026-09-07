import 'package:flutter/material.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';

/// Conta e segurança — grupo + sair em card separado (ChatGPT).
class PerfilContaSegurancaSection extends StatelessWidget {
  const PerfilContaSegurancaSection({
    super.key,
    required this.mute,
    required this.line,
    required this.onLogout,
    required this.onDeleteAccount,
    this.showMfa = false,
    this.onMfaTap,
  });

  final Color mute;
  final Color line;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final bool showMfa;
  final VoidCallback? onMfaTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxSettingsGroup(
          header: 'Conta e segurança',
          children: [
            if (showMfa)
              FxSettingsTile(
                icon: Icons.phonelink_lock_outlined,
                label: 'Autenticação em duas etapas',
                value: '',
                mute: mute,
                line: line,
                onTap: onMfaTap,
              ),
            FxSettingsTile(
              icon: Icons.gavel_outlined,
              label: 'Termos de uso',
              value: '',
              mute: mute,
              line: line,
              picker: true,
              onTap: () => FocuxLegal.openTerms(),
            ),
            FxSettingsTile(
              icon: Icons.shield_outlined,
              label: 'Política de privacidade',
              value: '',
              mute: mute,
              line: line,
              picker: true,
              showDivider: false,
              onTap: () => FocuxLegal.openPrivacy(),
            ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          children: [
            FxSettingsTile(
              icon: Icons.logout,
              label: 'Sair da conta',
              value: '',
              mute: mute,
              line: line,
              danger: true,
              onTap: onLogout,
            ),
            FxSettingsTile(
              icon: Icons.delete_forever_outlined,
              label: 'Excluir minha conta',
              value: '',
              mute: mute,
              line: line,
              danger: true,
              showDivider: false,
              onTap: onDeleteAccount,
            ),
          ],
        ),
      ],
    );
  }
}
