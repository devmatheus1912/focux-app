import 'package:flutter/material.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';

/// Conta e segurança — grupo + sair em card separado (ChatGPT).
///
/// Ajuda: site público de suporte (pré-lançamento — sem ticket/chat no app).
class PerfilContaSegurancaSection extends StatelessWidget {
  const PerfilContaSegurancaSection({
    super.key,
    required this.mute,
    required this.line,
    required this.onLogout,
    required this.onDeleteAccount,
    this.onConsentTap,
    this.showMfa = false,
    this.onMfaTap,
  });

  final Color mute;
  final Color line;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onConsentTap;
  final bool showMfa;
  final VoidCallback? onMfaTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxSettingsGroup(
          header: 'Ajuda',
          children: [
            FxSettingsTile(
              icon: Icons.support_agent_outlined,
              label: 'Ajuda e suporte',
              value: 'focuxpersonal.com/suporte',
              mute: mute,
              line: line,
              showDivider: false,
              onTap: () => FocuxLegal.openSupport(),
            ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
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
            if (onConsentTap != null)
              FxSettingsTile(
                icon: Icons.fact_check_outlined,
                label: 'Consentimentos',
                value: 'Termos, privacidade e aceite',
                mute: mute,
                line: line,
                showDivider: false,
                onTap: onConsentTap,
              )
            else ...[
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
