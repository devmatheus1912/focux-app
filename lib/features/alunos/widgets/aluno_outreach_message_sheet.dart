import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../providers/aluno_followup_provider.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../utils/aluno_outreach_display.dart';

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
    subtitle: 'Revise o texto antes de enviar.',
    icon: Icons.fact_check_outlined,
  );
}

class _AlunoOutreachMessageSheet extends ConsumerWidget {
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

  Future<void> _ackContact(WidgetRef ref) async {
    await ref.read(alunoFollowUpActionsProvider).markContactDone(alunoId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final displayName = fxTitleCaseName(alunoNome);
    final firstName = alunoPrimeiroNome(alunoNome);
    final checkin = icon == Icons.fact_check_outlined;

    Future<void> openChatWithDraft() async {
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.aluno360OutreachChatOpened,
          props: {'aluno_id': alunoId},
        ),
      );
      try {
        await _ackContact(ref);
      } catch (_) {
        // Chat still opens; follow-up sync can retry on 360 refresh.
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      context.push(
        '/alunos/$alunoId/chat',
        extra: alunoChatRouteExtra(
          nome: alunoNome,
          draft: message,
        ),
      );
    }

    Future<void> markContactDone() async {
      try {
        await _ackContact(ref);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        FeedbackHelper.showSuccess(context, 'Contato registrado');
      } catch (e) {
        if (!context.mounted) return;
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }

    return FxHomeSheetScaffold(
      isDark: isDark,
      leading: Icon(icon, color: primary, size: 18),
      title: title,
      subtitle: checkin ? 'Para $firstName · pronta para enviar' : subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OutreachMessageQuote(
            message: message,
            displayName: displayName,
            firstName: firstName,
            primary: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s4),
          FxLiquidPrimaryButton(
            label: alunoOutreachOpenChatLabel(),
            onPressed: openChatWithDraft,
          ),
          TextButton(
            onPressed: () async {
              await copySensitiveToClipboard(message);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              FeedbackHelper.showSuccess(
                context,
                alunoOutreachCopySuccess(),
              );
            },
            child: Text(alunoOutreachCopyLabel()),
          ),
          TextButton(
            onPressed: markContactDone,
            child: const Text('Contato feito'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: TokensStrip.s3),
            child: Text(
              alunoOutreachFooterHint(),
              textAlign: TextAlign.center,
              style: FxSettingsLayout.footer(color: mute),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutreachMessageQuote extends StatelessWidget {
  const _OutreachMessageQuote({
    required this.message,
    required this.displayName,
    required this.firstName,
    required this.primary,
    required this.isDark,
  });

  final String message;
  final String displayName;
  final String firstName;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final deep = BrandPalette.deep(primary);
    final soft = BrandPalette.softer(primary, dark: isDark);

    return Semantics(
      label: 'Mensagem sugerida para $displayName',
      readOnly: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              soft.withValues(alpha: isDark ? 0.55 : 0.92),
              (isDark ? EagleTokens.darkCard : Colors.white).withValues(
                alpha: isDark ? 0.88 : 0.98,
              ),
            ],
          ),
          border: Border.all(
            color: primary.withValues(alpha: isDark ? 0.22 : 0.14),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: deep),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: deep.withValues(alpha: isDark ? 0.88 : 1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Para $firstName',
                            style: FocuxHubTypography.chip(Colors.white)
                                .copyWith(letterSpacing: 0.2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: FocuxHubTypography.body(color: ink).copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
