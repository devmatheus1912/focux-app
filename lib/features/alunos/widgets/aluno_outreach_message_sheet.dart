import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
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
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? BrandPalette.deep(primary).withValues(alpha: 0.88)
                        : BrandPalette.deep(primary),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Para $firstName',
                style: FocuxHubTypography.chip(Colors.white).copyWith(
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Mensagem sugerida para $displayName',
            readOnly: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: BrandPalette.softer(primary, dark: isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primary.withValues(alpha: isDark ? 0.22 : 0.14),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 44,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      message,
                      style: FocuxHubTypography.body(color: ink).copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FxLiquidPrimaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Abrir chat',
            onPressed: () {
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
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'Copiar mensagem sugerida',
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await copySensitiveToClipboard(message);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  FeedbackHelper.showSuccess(
                    context,
                    'Mensagem copiada.',
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: primary,
                ),
                label: Text(
                  'Copiar mensagem',
                  style: FocuxHubTypography.cardTitle(color: primary),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(
                    color: primary.withValues(alpha: isDark ? 0.30 : 0.22),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
