import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../utils/hoje_personal_card.dart';
import '../utils/hoje_personal_dia.dart';

class _HojePersonalLinhaTile extends StatelessWidget {
  const _HojePersonalLinhaTile({
    required this.linha,
    required this.color,
    required this.onTap,
  });

  final HojePersonalLinha linha;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: linha.texto,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              linha.texto,
              style: FocuxHubTypography.bodyMuted(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HojePersonalCardView extends StatelessWidget {
  const HojePersonalCardView({
    super.key,
    required this.card,
    required this.onAction,
    required this.onVerPainel,
    this.linhas = const [],
    this.onLinha,
  });

  final HojePersonalCard card;
  final VoidCallback onAction;
  final VoidCallback onVerPainel;
  final List<HojePersonalLinha> linhas;
  final void Function(HojePersonalLinha linha)? onLinha;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s4,
        TokensStrip.s4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxStripCard(
            emphasize: true,
            glowStrength: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.hojePersonalAgora,
                  style: FocuxHubTypography.eyebrow(context, color: mute),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  card.titulo,
                  style: FocuxHubTypography.pageTitle(
                    context,
                    color: chrome.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  card.frase,
                  style: FocuxHubTypography.bodyMuted(color: mute),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (linhas.isNotEmpty) ...[
                  const SizedBox(height: TokensStrip.s3),
                  for (final linha in linhas)
                    _HojePersonalLinhaTile(
                      linha: linha,
                      color: chrome.ink,
                      onTap: onLinha == null ? null : () => onLinha!(linha),
                    ),
                ],
                if (card.temBotao) ...[
                  const SizedBox(height: TokensStrip.s4),
                  FxLiquidPrimaryButton(
                    label: card.botao!,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onVerPainel,
              style: TextButton.styleFrom(
                foregroundColor: mute,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                s.hojePersonalVerPainel,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showHojePersonalPainel(
  BuildContext context, {
  required List<Widget> children,
}) {
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return FxHomeSheetSurface(
        isDark: isDark,
        expand: true,
        child: ListView(
          children: [
            FxHomeSheetHandle(isDark: isDark),
            const SizedBox(height: TokensStrip.s4),
            ...children,
          ],
        ),
      );
    },
  );
}
