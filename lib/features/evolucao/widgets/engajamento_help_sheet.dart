import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showEngajamentoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o engajamento',
    subtitle: 'Aderência do aluno e o próximo passo.',
    tips: const [
      FxHelpTip(
        'Linha do tempo',
        'Treinos, medidas e mensagens da janela escolhida. Troque o período no chip.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Próxima ação',
        'Toque num evento para abrir o chat, a evolução ou os treinos. O botão de baixo registra uma medida.',
        icon: 'plus',
      ),
    ],
  );
}
