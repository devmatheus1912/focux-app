import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showReferralHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como indicar e ganhar',
    subtitle: 'Seu código e o convite que o outro personal usa para entrar.',
    tips: const [
      FxHelpTip(
        'Código',
        'É o identificador da indicação. Os usos mostram quem já entrou com ele.',
        icon: 'users',
      ),
      FxHelpTip(
        'Convite',
        'Copia texto + link. Some da área de transferência em 1 minuto.',
        icon: 'spark',
      ),
    ],
  );
}
