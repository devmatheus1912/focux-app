import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';

Future<void> showPerfilPublicLinkSheet(
  BuildContext context, {
  required String slug,
}) async {
  final url = Env.landingPageUrl(slug);
  final label = Env.landingPageDisplayLabel(slug);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;

  await showFxHomeSheet<void>(
    context,
    builder: (ctx) => FxHomeSheetScaffold(
      isDark: isDark,
      leading: Icon(Icons.link_outlined, color: primary, size: 22),
      title: 'Link de acesso',
      subtitle: 'Compartilhe com seus alunos para eles entrarem no app com seu código já preenchido.',
      child: _PerfilPublicLinkBody(url: url, label: label, slug: slug),
    ),
  );
}

class _PerfilPublicLinkBody extends StatelessWidget {
  const _PerfilPublicLinkBody({
    required this.url,
    required this.label,
    required this.slug,
  });

  final String url;
  final String label;
  final String slug;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          url,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
        const SizedBox(height: TokensStrip.s3),
        Text(
          'Código: $slug',
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
        const SizedBox(height: TokensStrip.s1),
        Text(
          'Para adicionar um aluno novo, use o link de convite em Alunos.',
          style: FocuxHubTypography.bodyMuted(color: chrome.mute)
              .copyWith(fontSize: 12),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxLiquidPrimaryButton(
          label: 'Copiar link',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (!context.mounted) return;
            FeedbackHelper.showSuccess(context, 'Link copiado');
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: TokensStrip.s2),
        TextButton(
          onPressed: () async {
            final uri = Uri.tryParse(url);
            if (uri == null) return;
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: const Text('Abrir no navegador'),
        ),
      ],
    );
  }
}
