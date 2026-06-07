import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/alunos/constants/aluno_360_layout.dart';
import '../theme/design_tokens.dart';

/// Where transient feedback should anchor on screen.
enum FeedbackPlacement {
  /// Default floating snackbar above bottom inset / nav bar.
  standard,

  /// Below pinned Aluno 360 header — avoids overlap with scrollable cards + sticky CTA.
  operacaoTop,
}

/// Premium snackbar feedback — uses design tokens, tinted fills,
/// and haptic feedback for every state.
class FeedbackHelper {
  static ScaffoldMessengerState messengerOf(BuildContext context) {
    return ScaffoldMessenger.of(context);
  }

  static EdgeInsets _snackMargin(
    BuildContext context, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    if (placement == FeedbackPlacement.operacaoTop) {
      return Aluno360Layout.operacaoTopSnackMargin(context);
    }
    if (reserveBottom <= 0) {
      return const EdgeInsets.fromLTRB(16, 0, 16, 16);
    }
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasBottomBar =
        Scaffold.maybeOf(context)?.widget.bottomNavigationBar != null;
    final bottomMargin =
        bottomInset + (hasBottomBar ? 88 : 16) + reserveBottom;
    return EdgeInsets.fromLTRB(16, 0, 16, bottomMargin);
  }

  static void showSnackBar(
    BuildContext context,
    SnackBar snackBar, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    final margin = _snackMargin(
      context,
      reserveBottom: reserveBottom,
      placement: placement,
    );
    final useFloating =
        placement == FeedbackPlacement.operacaoTop || reserveBottom > 0;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackBar.content,
        action: snackBar.action,
        backgroundColor: snackBar.backgroundColor,
        behavior:
            useFloating ? SnackBarBehavior.floating : snackBar.behavior,
        shape: snackBar.shape,
        duration: snackBar.duration,
        elevation: snackBar.elevation,
        margin: useFloating ? margin : snackBar.margin,
        dismissDirection:
            placement == FeedbackPlacement.operacaoTop
                ? DismissDirection.up
                : snackBar.dismissDirection,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    HapticFeedback.mediumImpact();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.good,
      icon: Icons.check_circle_rounded,
      reserveBottom: reserveBottom,
      placement: placement,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    HapticFeedback.heavyImpact();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.bad,
      icon: Icons.error_outline_rounded,
      reserveBottom: reserveBottom,
      placement: placement,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    HapticFeedback.selectionClick();
    _showSnackbar(
      context,
      message,
      fill: Theme.of(context).colorScheme.primary,
      icon: Icons.info_outline_rounded,
      reserveBottom: reserveBottom,
      placement: placement,
    );
  }

  static void showWarn(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    HapticFeedback.selectionClick();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.warn,
      icon: Icons.warning_amber_rounded,
      reserveBottom: reserveBottom,
      placement: placement,
    );
  }

  /// Operação tab feedback — pins below header so scroll position never hides CTAs.
  static void showOperacaoSuccess(BuildContext context, String message) {
    showSuccess(context, message, placement: FeedbackPlacement.operacaoTop);
  }

  static void showOperacaoWarn(BuildContext context, String message) {
    showWarn(context, message, placement: FeedbackPlacement.operacaoTop);
  }

  static void showOperacaoError(BuildContext context, String message) {
    showError(context, message, placement: FeedbackPlacement.operacaoTop);
  }

  static void _showSnackbar(
    BuildContext context,
    String message, {
    required Color fill,
    required IconData icon,
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snackFill = isDark ? EagleTokens.darkCardHi : EagleTokens.ink;
    final margin = _snackMargin(
      context,
      reserveBottom: reserveBottom,
      placement: placement,
    );

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
        margin: margin,
        duration: const Duration(seconds: 3),
        elevation: 0,
        dismissDirection:
            placement == FeedbackPlacement.operacaoTop
                ? DismissDirection.up
                : DismissDirection.down,
      ),
    );
  }
}
