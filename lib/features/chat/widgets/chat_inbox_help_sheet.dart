import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showChatInboxHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar as mensagens',
    subtitle: 'A caixa do personal. A conversa em si continua no fio do aluno.',
    tips: const [
      FxHelpTip(
        'Conversas',
        'Toque no aluno para abrir o fio. A lista só aponta o caminho — não envia mensagem.',
        icon: 'chat',
      ),
      FxHelpTip(
        'Abas',
        'Todas, não lidas e arquivadas. O recorte vem do BFF da caixa.',
        icon: 'article',
      ),
      FxHelpTip(
        'Arquivar e fixar',
        'Arraste para a esquerda para arquivar. Para a direita, fixa no topo.',
        icon: 'clock',
      ),
      FxHelpTip(
        'Nova conversa',
        'O botão de baixo escolhe o aluno. Segure uma linha para selecionar e limpar.',
        icon: 'plus',
      ),
    ],
  );
}
