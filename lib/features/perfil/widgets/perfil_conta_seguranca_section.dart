import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/support/intercom_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import 'perfil_biometria_tile.dart';
import 'perfil_sobre_grupo.dart';
import '../../../core/theme/fx_icons.dart';

/// Conta e segurança — grupo + sair em card separado.
///
/// Ajuda: abre o Messenger do Intercom como overlay.
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
              icon: FxIcons.suporte,
              label: 'Ajuda e suporte',
              value: '',
              mute: mute,
              line: line,
              showDivider: false,
              onTap: () => IntercomService.openMessenger(),
            ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Conta e segurança',
          children: [
            FxSettingsTile(
              icon: FxIcons.notificacao,
              label: 'Notificações',
              value: '',
              mute: mute,
              line: line,
              onTap: () => context.push('/perfil/notificacoes'),
            ),
            PerfilBiometriaTile(mute: mute, line: line),
            if (showMfa)
              FxSettingsTile(
                icon: FxIcons.cadeado,
                label: 'Autenticação em duas etapas',
                value: '',
                mute: mute,
                line: line,
                showDivider: onConsentTap != null,
                onTap: onMfaTap,
              ),
            if (onConsentTap != null)
              FxSettingsTile(
                icon: FxIcons.conferir,
                label: 'Consentimentos',
                value: '',
                mute: mute,
                line: line,
                showDivider: false,
                onTap: onConsentTap,
              ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        PerfilSobreGrupo(mute: mute, line: line),
        const SizedBox(height: FxSettingsLayout.groupGap),
        // Sair e excluir no fim, juntos. Sair não abre tela: sem seta.
        FxSettingsGroup(
          children: [
            FxSettingsTile(
              icon: FxIcons.sair,
              label: 'Sair da conta',
              value: '',
              mute: mute,
              line: line,
              accessory: const SizedBox.shrink(),
              onTap: onLogout,
            ),
            FxSettingsTile(
              icon: FxIcons.excluir,
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
