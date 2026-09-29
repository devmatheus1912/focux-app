import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../router/safe_navigation.dart';
import 'feedback_helper.dart';

/// A ação ficou na fila offline: avisa o pendente e sai da tela. Ficar no
/// formulário convidaria a um segundo envio, que enfileiraria outra cópia.
void leaveWithQueuedNotice(BuildContext context, String fallbackLocation) {
  if (!context.mounted) return;
  FeedbackHelper.showWarn(context, S.of(context).acaoEnfileiradaOffline);
  safePopOrGo(context, fallbackLocation);
}
