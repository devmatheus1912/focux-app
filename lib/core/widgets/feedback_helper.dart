import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/alunos/constants/aluno_360_layout.dart';
import '../../l10n/app_localizations.dart';
import '../api/offline_queued_ack.dart';
import '../api/plan_upgrade_error_hub.dart';
import '../theme/design_tokens.dart';
import '../utils/friendly_error.dart';

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

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnackBar(
    BuildContext context,
    SnackBar snackBar, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    if (!context.mounted) return null;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;
    final margin = _snackMargin(
      context,
      reserveBottom: reserveBottom,
      placement: placement,
    );
    final useFloating =
        placement == FeedbackPlacement.operacaoTop || reserveBottom > 0;
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        content: snackBar.content,
        action: snackBar.action,
        backgroundColor: snackBar.backgroundColor,
        behavior:
            useFloating ? SnackBarBehavior.floating : snackBar.behavior,
        shape: snackBar.shape,
        duration: snackBar.duration,
        persist: snackBar.persist,
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
    // A sheet de upgrade já explica o erro de plano; toast por baixo é ruído.
    if (PlanUpgradeErrorHub.isShowing) return;
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

  /// Aviso com "Desfazer". Resolve `true` só se o usuário tocar na ação.
  static Future<bool> showUndo(
    BuildContext context,
    String message, {
    String actionLabel = 'Desfazer',
    Duration duration = const Duration(seconds: 4),
  }) async {
    final controller = showSnackBar(
      context,
      SnackBar(
        content: Text(message),
        duration: duration,
        persist: false,
        action: SnackBarAction(label: actionLabel, onPressed: () {}),
      ),
    );
    if (controller == null) return false;
    return await controller.closed == SnackBarClosedReason.action;
  }

  static void showInfo(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
    FeedbackPlacement placement = FeedbackPlacement.standard,
  }) {
    if (!context.mounted) return;
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

  /// Falha de mutação. Ação que só entrou na fila offline não é erro nem
  /// sucesso: avisa que sobe quando a rede voltar.
  static void showApiFailure(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    if (error is OfflineQueuedException) {
      showWarn(context, S.of(context).acaoEnfileiradaOffline);
      return;
    }
    if (PlanUpgradeErrorHub.presenter != null &&
        PlanUpgradeErrorHub.isUpgradeError(error)) {
      unawaited(
        PlanUpgradeErrorHub.present(error, context: context).then((shown) {
          if (!shown && context.mounted) {
            showError(context, friendlyError(error, fallback: fallback));
          }
        }),
      );
      return;
    }
    showError(context, friendlyError(error, fallback: fallback));
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
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snackFill = isDark ? EagleTokens.darkCardHi : EagleTokens.ink;
    final margin = _snackMargin(
      context,
      reserveBottom: reserveBottom,
      placement: placement,
    );

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
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
