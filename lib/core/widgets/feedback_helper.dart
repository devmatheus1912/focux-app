import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../api/offline_queued_ack.dart';
import '../api/plan_upgrade_error_hub.dart';
import '../theme/design_tokens.dart';
import '../utils/friendly_error.dart';
import '../theme/fx_icons.dart';
import '../theme/tokens_strip.dart';
import '../theme/chao_da_marca.dart';

/// Premium snackbar feedback — uses design tokens, tinted fills,
/// and haptic feedback for every state.
class FeedbackHelper {
  static ScaffoldMessengerState messengerOf(BuildContext context) {
    return ScaffoldMessenger.of(context);
  }

  static EdgeInsets _snackMargin(
    BuildContext context, {
    double reserveBottom = 0,
  }) {
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
  }) {
    if (!context.mounted) return null;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;
    final margin = _snackMargin(
      context,
      reserveBottom: reserveBottom,
    );
    final useFloating =
reserveBottom > 0;
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
        dismissDirection: snackBar.dismissDirection,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
  }) {
    HapticFeedback.mediumImpact();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.good,
      icon: FxIcons.concluido,
      reserveBottom: reserveBottom,
    );
  }

  /// Sucesso com uma ação, como abrir a rotina depois de entrar no fim da fila.
  static void showSuccessAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.mediumImpact();
    showSnackBar(
      context,
      SnackBar(
        content: Text(message),
        backgroundColor: EagleTokens.good,
        duration: duration,
        // Com ação, o SnackBar fica até ser tocado (Flutter ≥ 3.29) e atravessa telas.
        persist: false,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
  }) {
    // A sheet de upgrade já explica o erro de plano; toast por baixo é ruído.
    if (PlanUpgradeErrorHub.isShowing) return;
    HapticFeedback.heavyImpact();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.bad,
      icon: FxIcons.erro,
      reserveBottom: reserveBottom,
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
  }) {
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    _showSnackbar(
      context,
      message,
      fill: Theme.of(context).colorScheme.primary,
      icon: FxIcons.info,
      reserveBottom: reserveBottom,
    );
  }

  static void showWarn(
    BuildContext context,
    String message, {
    double reserveBottom = 0,
  }) {
    HapticFeedback.selectionClick();
    _showSnackbar(
      context,
      message,
      fill: EagleTokens.warn,
      icon: FxIcons.alerta,
      reserveBottom: reserveBottom,
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

  static void _showSnackbar(
    BuildContext context,
    String message, {
    required Color fill,
    required IconData icon,
    double reserveBottom = 0,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snackFill = isDark ? context.tons.superficieAlta : EagleTokens.ink;
    final margin = _snackMargin(
      context,
      reserveBottom: reserveBottom,
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
                  fontSize: TokensStrip.fontBodySm,
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
        dismissDirection: DismissDirection.down,
      ),
    );
  }
}
