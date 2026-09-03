import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/focux_microcopy.dart';
import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';
import 'fx_motion.dart';

/// Sheet de formulário curto — substitui `AlertDialog` com campos.
///
/// Layout igual à busca rápida da Home: superfície expandida +
/// [Expanded] + scroll. O [child] fica com os inputs; o caller
/// guarda os controllers. Retorna `true` só se o usuário confirmar.
Future<bool> showFxFormSheet(
  BuildContext context, {
  required String title,
  required Widget child,
  required String confirmLabel,
  String? subtitle,
  IconData icon = Icons.edit_outlined,
  String cancelLabel = FocuxMicrocopy.cancelar,
  bool destructive = false,
}) async {
  final confirmed = await showFxHomeSheet<bool>(
    context,
    builder:
        (ctx) => _FxFormSheet(
          title: title,
          subtitle: subtitle,
          icon: icon,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: destructive,
          child: child,
        ),
  );
  return confirmed ?? false;
}

/// Sheet informativo (Entendi / Continuar) — substitui `AlertDialog` sem
/// confirmação destrutiva. [body] entra abaixo da [message], se houver.
Future<void> showFxNoticeSheet(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  String actionLabel = 'Entendi',
  IconData icon = Icons.info_outline_rounded,
  List<Widget> extraActions = const [],
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _FxNoticeSheet(
          title: title,
          message: message,
          body: body,
          actionLabel: actionLabel,
          icon: icon,
          extraActions: extraActions,
        ),
  );
}

class _FxFormSheet extends StatelessWidget {
  const _FxFormSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final accent = destructive ? EagleTokens.bad : Theme.of(context).colorScheme.primary;
    final onAccent = destructive ? Colors.white : Theme.of(context).colorScheme.onPrimary;
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            subtitle: subtitle,
            leading: Icon(icon, color: accent, size: 18),
          ),
          SizedBox(height: TokensStrip.s4),
          Expanded(
            child: SingleChildScrollView(child: child),
          ),
          const SizedBox(height: 20),
          if (destructive)
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(confirmLabel),
              ),
            )
          else
            FxLiquidPrimaryButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelLabel,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FxNoticeSheet extends StatelessWidget {
  const _FxNoticeSheet({
    required this.title,
    required this.message,
    required this.body,
    required this.actionLabel,
    required this.icon,
    required this.extraActions,
  });

  final String title;
  final String? message;
  final Widget? body;
  final String actionLabel;
  final IconData icon;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primary = Theme.of(context).colorScheme.primary;
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;
    final messageText = message?.trim();

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            leading: Icon(icon, color: primary, size: 18),
          ),
          SizedBox(height: TokensStrip.s3),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (messageText != null && messageText.isNotEmpty)
                    Text(
                      messageText,
                      textAlign: TextAlign.center,
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  if (body != null) ...[
                    if (messageText != null && messageText.isNotEmpty)
                      SizedBox(height: TokensStrip.s3),
                    body!,
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...extraActions,
          FxLiquidPrimaryButton(
            label: actionLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
