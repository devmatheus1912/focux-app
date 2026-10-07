import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_invite_copy.dart';

/// Compartilha o link de ativação (aluno novo ou reenvio).
Future<void> showAlunoLinkAtivacaoSheet({
  required BuildContext context,
  required String nome,
  required String link,
  String? whatsapp,
  bool reenvio = false,
  VoidCallback? onDone,
}) {
  final s = S.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final chrome = ShellChrome.forBrightness(context, isDark);
  final convite = alunoAtivacaoMessage(
    s,
    nome: nome,
    link: link,
    reenvio: reenvio,
  );
  final whatsAppUri = BrPhone.whatsAppUri(whatsapp, text: convite);
  final first = nome.trim().split(RegExp(r'\s+')).first;

  Future<void> copiar(BuildContext ctx, String aviso) async {
    await copySensitiveToClipboard(convite);
    HapticFeedback.mediumImpact();
    if (ctx.mounted) Navigator.of(ctx).pop();
    if (context.mounted) FeedbackHelper.showSuccess(context, aviso);
  }

  return showFxHomeSheet<void>(
    context,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) {
      return FxHomeSheetScaffold(
        isDark: isDark,
        leading: Icon(
          reenvio ? Icons.link_rounded : Icons.check_rounded,
          color: EagleTokens.good,
          size: 22,
        ),
        title: reenvio ? s.alunoLinkReenvioTitulo : s.alunoLinkCadastradoTitulo,
        subtitle:
            reenvio
                ? s.alunoLinkReenvioTexto(first)
                : s.alunoLinkCadastradoTexto(first),
        trailing: const SizedBox.shrink(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.alunoLinkValidade,
              style: FxSettingsLayout.rowLabel(color: chrome.mute),
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
            FxLiquidPrimaryButton(
              label:
                  whatsAppUri != null
                      ? s.alunoLinkEnviarWhatsApp
                      : s.alunoLinkCopiar,
              onPressed: () async {
                if (whatsAppUri == null) {
                  await copiar(ctx, s.alunoLinkCopiado);
                } else {
                  HapticFeedback.mediumImpact();
                  final ok = await launchUrl(
                    whatsAppUri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!ok) {
                    if (ctx.mounted) {
                      await copiar(ctx, s.alunoLinkWhatsAppFalhou);
                    }
                  } else if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                }
                onDone?.call();
              },
            ),
            if (whatsAppUri != null)
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    FxHomeSheetChrome.touchTarget,
                    FxHomeSheetChrome.touchTarget,
                  ),
                ),
                onPressed: () async {
                  await copiar(ctx, s.alunoLinkCopiado);
                  onDone?.call();
                },
                child: Text(s.alunoLinkCopiar),
              ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  FxHomeSheetChrome.touchTarget,
                  FxHomeSheetChrome.touchTarget,
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onDone?.call();
              },
              child: Text(
                s.alunoLinkFechar,
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
