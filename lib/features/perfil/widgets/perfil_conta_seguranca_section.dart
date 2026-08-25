import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/design_tokens.dart';
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
  });

  final Color mute;
  final Color line;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxSettingsGroup(
          header: 'Conta e segurança',
          children: [
            FxSettingsTile(
              icon: Icons.gavel_outlined,
              label: 'Termos de uso',
              value: '',
              mute: mute,
              line: line,
              onTap: () => FocuxLegal.openTerms(),
            ),
            FxSettingsTile(
              icon: Icons.shield_outlined,
              label: 'Política de privacidade',
              value: '',
              mute: mute,
              line: line,
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
              showDivider: false,
              onTap: onLogout,
            ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.footerAfterGroup),
        Center(
          child: Semantics(
            button: true,
            label: 'Excluir minha conta. Ação destrutiva',
            hint: 'Confirmação será solicitada',
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onDeleteAccount();
              },
              style: TextButton.styleFrom(
                foregroundColor: EagleTokens.bad,
                minimumSize: const Size(48, 48),
                textStyle: FxSettingsLayout.footer(color: EagleTokens.bad),
              ),
              child: const Text('Excluir minha conta'),
            ),
          ),
        ),
      ],
    );
  }
}
