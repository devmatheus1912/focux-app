import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/widgets/feedback_helper.dart';

/// Copia o link da página de vendas (`/p/{slug}`).
void copyStorefrontLink(BuildContext context, String? slug) {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para gerar o link da sua página de vendas.',
    );
    return;
  }
  Clipboard.setData(ClipboardData(text: Env.landingPageUrl(slug)));
  FeedbackHelper.showSuccess(context, 'Link copiado!');
}

/// "Ver como o cliente vê": abre a página de verdade (substitui a Vitrine).
Future<void> openStorefrontPreview(BuildContext context, String? slug) async {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para abrir sua página de vendas.',
    );
    return;
  }
  final uri = Uri.parse(Env.landingPageUrl(slug));
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
