import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';

/// Dado móvel com "Economizar dados móveis": o vídeo só baixa quando o aluno
/// toca em "Ver vídeo".
class CheckinVideoSobPedido extends StatelessWidget {
  const CheckinVideoSobPedido({super.key, required this.brand, required this.dark, required this.onVer});

  final Color brand;
  final bool dark;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? EagleTokens.darkCardHi : TokensStrip.borderDefault,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withValues(alpha: 0.22)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(TokensStrip.s3),
      child: FxTonalButton(
        label: s.checkinVerVideo,
        icon: FxIcons.play,
        onPressed: onVer,
      ),
    );
  }
}

class CheckinVideoFallback extends StatelessWidget {
  final Color brand;
  final bool dark;

  const CheckinVideoFallback({
    super.key,
    required this.brand,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? EagleTokens.darkCardHi : TokensStrip.borderDefault,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FxIcons.playCirculo, color: brand, size: 34),
          const SizedBox(height: 6),
          Text(
            S.of(context).checkinMidiaVideoPersonal,
            style: TextStyle(
              color: brand,
              fontSize: TokensStrip.fontRotulo,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
