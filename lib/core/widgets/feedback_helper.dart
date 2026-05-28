import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

/// Premium snackbar feedback — uses design tokens, tinted fills,
/// and haptic feedback for every state.
class FeedbackHelper {
  static ScaffoldMessengerState messengerOf(BuildContext context) {
    return ScaffoldMessenger.of(context);
  }

  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.good,
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.bad,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    _showSnackbar(
      context,
      message,
      fill: Theme.of(context).colorScheme.primary,
      icon: Icons.info_outline_rounded,
    );
  }

  static void showWarn(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.warn,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void _showSnackbar(
    BuildContext context,
    String message, {
    required Color fill,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snackFill = isDark ? EagleTokens.darkCardHi : EagleTokens.ink;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: fill.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: fill, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: snackFill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusMd),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        elevation: 0,
      ),
    );
  }
}
