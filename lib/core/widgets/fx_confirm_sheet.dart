import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/focux_microcopy.dart';
import '../theme/design_tokens.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';

/// Confirmação canônica no chrome da Home — substitui `AlertDialog` de
/// confirmar/cancelar. Retorna `true` só se o usuário confirmar.
///
/// Use `destructive: true` para ações irreversíveis (excluir, arquivar):
/// o CTA fica em `EagleTokens.bad` e dispara haptic pesado.
Future<bool> showFxConfirmSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? subtitle,
  String? message,
  IconData icon = Icons.help_outline_rounded,
  IconData? confirmIcon,
  String cancelLabel = FocuxMicrocopy.cancelar,
  bool destructive = false,
}) async {
  final confirmed = await showFxHomeSheet<bool>(
    context,
    builder:
        (ctx) => _FxConfirmSheet(
          title: title,
          subtitle: subtitle,
          message: message,
          icon: icon,
          confirmIcon: confirmIcon,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: destructive,
        ),
  );
  return confirmed ?? false;
}

class _FxConfirmSheet extends StatelessWidget {
  const _FxConfirmSheet({
    required this.title,
    required this.subtitle,
    required this.message,
    required this.icon,
    required this.confirmIcon,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String? subtitle;
  final String? message;
  final IconData icon;
  final IconData? confirmIcon;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final accent = destructive ? EagleTokens.bad : theme.colorScheme.primary;
    final onAccent = destructive ? Colors.white : theme.colorScheme.onPrimary;

    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (message != null && message!.trim().isNotEmpty) ...[
            SizedBox(height: TokensStrip.s3),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (destructive) HapticFeedback.heavyImpact();
                Navigator.of(context).pop(true);
              },
              icon:
                  confirmIcon == null
                      ? const SizedBox.shrink()
                      : Icon(confirmIcon, size: 18),
              label: Text(confirmLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelLabel,
                style: TextStyle(color: mute, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
