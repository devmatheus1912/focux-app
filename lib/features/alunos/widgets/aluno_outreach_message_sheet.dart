import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../utils/aluno360_operacao_logic.dart';

/// Opens a polished outreach sheet with copy + chat actions.
Future<void> showAlunoOutreachMessageSheet(
  BuildContext context, {
  required int alunoId,
  required String alunoNome,
  required String message,
  String title = 'Mensagem sugerida',
  String subtitle = 'Revise antes de enviar ao aluno.',
  IconData icon = Icons.message_outlined,
}) async {
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (!reduceMotion) {
    HapticFeedback.selectionClick();
  }
  await showFxHomeSheet<void>(
    context,
    builder:
        (sheetContext) => _AlunoOutreachMessageSheet(
          alunoId: alunoId,
          alunoNome: alunoNome,
          message: message,
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
  );
}

Future<void> showAlunoCheckinMessageSheet(
  BuildContext context, {
  required int alunoId,
  required String alunoNome,
}) {
  return showAlunoOutreachMessageSheet(
    context,
    alunoId: alunoId,
    alunoNome: alunoNome,
    message: checkinMensagemPronta(alunoNome),
    title: 'Mensagem de check-in',
    subtitle: 'Revise o texto antes de enviar a $alunoNome.',
    icon: Icons.fact_check_outlined,
  );
}

class _AlunoOutreachMessageSheet extends StatelessWidget {
  const _AlunoOutreachMessageSheet({
    required this.alunoId,
    required this.alunoNome,
    required this.message,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final int alunoId;
  final String alunoNome;
  final String message;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final displayName = fxTitleCaseName(alunoNome);
    final firstName = alunoPrimeiroNome(alunoNome);

    return FxHomeSheetScaffold(
      isDark: isDark,
      leading: Icon(icon, color: primary, size: 18),
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxSettingsGroup(
            header: 'Prévia',
            caption: 'Para $firstName',
            accent: primary,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
                child: Semantics(
                  label: 'Mensagem sugerida para $displayName',
                  readOnly: true,
                  child: Text(
                    message,
                    style: FocuxHubTypography.body(color: ink).copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxSettingsGroup(
            header: 'Enviar',
            children: [
              FxSettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Abrir chat',
                subtitle: 'Mensagem já preenchida no rascunho',
                value: '',
                highlight: true,
                accent: primary,
                onTap: () {
                  unawaited(
                    AnalyticsService.instance.track(
                      ProductEvents.aluno360OutreachChatOpened,
                      props: {'aluno_id': alunoId},
                    ),
                  );
                  Navigator.of(context).pop();
                  context.push(
                    '/alunos/$alunoId/chat',
                    extra: alunoChatRouteExtra(
                      nome: alunoNome,
                      draft: message,
                    ),
                  );
                },
              ),
              FxSettingsTile(
                icon: Icons.copy_rounded,
                label: 'Copiar mensagem',
                subtitle: 'Cole no WhatsApp ou outro app',
                value: '',
                showDivider: false,
                onTap: () async {
                  await copySensitiveToClipboard(message);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  FeedbackHelper.showSuccess(
                    context,
                    'Mensagem copiada.',
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.groupPadH,
              TokensStrip.s2,
              FxSettingsLayout.groupPadH,
              0,
            ),
            child: Text(
              'Ajuste o tom se precisar antes de enviar.',
              style: FxSettingsLayout.footer(color: mute),
            ),
          ),
        ],
      ),
    );
  }
}
