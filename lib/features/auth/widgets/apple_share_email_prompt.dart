import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';

/// Antes do Sign in with Apple: pedir para compartilhar o e-mail real.
Future<bool> confirmAppleShareEmail(BuildContext context) {
  return showFxConfirmSheet(
    context,
    title: 'Compartilhar e-mail na Apple',
    message:
        'Na próxima tela da Apple, escolha Compartilhar meu e-mail '
        '(não Ocultar). Assim recibos e o link da sua landing ficam limpos — '
        'sem privaterelay.appleid.com.',
    confirmLabel: 'Continuar com Apple',
    cancelLabel: 'Cancelar',
  );
}

String appleShareEmailHint() =>
    'Na Apple, escolha Compartilhar meu e-mail — não Ocultar.';

Color appleShareEmailHintColor() => EagleTokens.textSecondary;
