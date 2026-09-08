import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAnamneseHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a anamnese',
    subtitle: 'Você solicita e revisa. O aluno preenche a ficha.',
    tips: const [
      FxHelpTip(
        'Solicitar',
        'O botão de baixo pede a ficha. O aluno preenche PAR-Q+, saúde e hábitos.',
        icon: 'article',
      ),
      FxHelpTip(
        'Revisar',
        'Quando o aluno envia, marque revisada, peça atestado ou peça atualização. A ficha é só leitura.',
        icon: 'circle-check',
      ),
      FxHelpTip(
        'Chat',
        'Dúvida pontual vai no chat do aluno. Isso não substitui a ficha.',
        icon: 'message-circle',
      ),
    ],
  );
}
