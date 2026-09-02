import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_invite_copy.dart';

Future<void> showAddAlunoSenhaSheet({
  required BuildContext context,
  required Aluno aluno,
  required VoidCallback onDone,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final chrome = ShellChrome.forDark(isDark);
  final senha = aluno.senhaProvisoria ?? '';
  final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
  final hasWhatsapp = whatsappNumber.isNotEmpty;
  final convite = alunoInviteMessage(
    nome: aluno.nome,
    email: aluno.email,
    senhaProvisoria: senha,
  );

  Future<void> copyConvite() async {
    await copySensitiveToClipboard(convite);
    HapticFeedback.mediumImpact();
  }

  return showFxHomeSheet<void>(
    context,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) {
      return FxHomeSheetScaffold(
        isDark: isDark,
        leading: Icon(Icons.check_rounded, color: EagleTokens.good, size: 22),
        title: 'Aluno cadastrado',
        subtitle: 'Compartilhe o convite para o aluno acessar o app.',
        trailing: const SizedBox.shrink(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxSettingsGroup(
              header: 'Senha provisória',
              caption: 'O aluno deve trocar a senha no primeiro acesso.',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
                  child: Center(
                    child: Text(
                      senha,
                      textAlign: TextAlign.center,
                      style: FxSettingsLayout.rowLabel(
                        color: chrome.ink,
                      ).copyWith(
                        fontSize: 28,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
            FxSettingsGroup(
              children: [
                if (hasWhatsapp)
                  FxSettingsTile(
                    icon: Icons.send_rounded,
                    label: 'Enviar no WhatsApp',
                    value: '',
                    highlight: true,
                    showDivider: true,
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final uri = Uri.parse(
                        'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(convite)}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        onDone();
                        return;
                      }
                      await copyConvite();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        FeedbackHelper.showSuccess(
                          context,
                          'Mensagem copiada. Abra o WhatsApp e envie ao aluno.',
                        );
                      }
                      onDone();
                    },
                  ),
                FxSettingsTile(
                  icon: Icons.copy_rounded,
                  label: 'Copiar convite',
                  value: '',
                  showDivider: false,
                  onTap: () async {
                    await copyConvite();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      FeedbackHelper.showSuccess(context, 'Convite copiado.');
                    }
                    onDone();
                  },
                ),
              ],
            ),
            const SizedBox(height: TokensStrip.s3),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  FxHomeSheetChrome.touchTarget,
                  FxHomeSheetChrome.touchTarget,
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onDone();
              },
              child: Text(
                'Fechar',
                style: TextStyle(
                  color: chrome.mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
