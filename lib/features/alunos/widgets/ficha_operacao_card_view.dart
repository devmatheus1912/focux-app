import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/ficha_operacao_card.dart';

class FichaOperacaoCardView extends StatelessWidget {
  const FichaOperacaoCardView({
    super.key,
    required this.card,
    required this.onAction,
    this.carregando = false,
  });

  final FichaOperacaoCard card;
  final VoidCallback onAction;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.fichaOperacaoAgora,
          style: FocuxHubTypography.eyebrow(context, color: mute),
        ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          card.titulo,
          style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
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
        if (card.temBotao) ...[
          const SizedBox(height: TokensStrip.s4),
          FxLiquidPrimaryButton(
            label: card.botao!,
            loading: carregando,
            onPressed: carregando ? null : onAction,
          ),
        ],
      ],
    );
  }
}

class FichaOperacaoVerFichaButton extends StatelessWidget {
  const FichaOperacaoVerFichaButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: mute,
          padding: EdgeInsets.zero,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          S.of(context).fichaOperacaoVerFicha,
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Future<void> showFichaOperacaoPainel(
  BuildContext context, {
  required Widget child,
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
            child,
          ],
        ),
      );
    },
  );
}
