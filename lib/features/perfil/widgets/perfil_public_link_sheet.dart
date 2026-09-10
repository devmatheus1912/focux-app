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
      title: 'Link público',
      subtitle: 'Copie ou abra a landing no ar.',
      child: _PerfilPublicLinkBody(url: url, label: label),
    ),
  );
}

class _PerfilPublicLinkBody extends StatelessWidget {
  const _PerfilPublicLinkBody({required this.url, required this.label});

  final String url;
  final String label;

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
