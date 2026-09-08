import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/feedback_helper.dart';

Future<void> copyLandingLink(
  BuildContext context, {
  required String url,
  required String successMessage,
  double reserveBottom = 0,
}) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  FeedbackHelper.showSuccess(
    context,
    successMessage,
    reserveBottom: reserveBottom,
  );
}

Future<void> openLandingLink(
  BuildContext context, {
  required String url,
}) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (opened) {
      FeedbackHelper.showInfo(context, 'Abrindo como seu cliente vê…');
    } else {
      FeedbackHelper.showWarn(context, 'Não foi possível abrir o link.');
    }
  } catch (_) {
    if (!context.mounted) return;
    FeedbackHelper.showError(context, 'Não foi possível abrir a página.');
  }
}
