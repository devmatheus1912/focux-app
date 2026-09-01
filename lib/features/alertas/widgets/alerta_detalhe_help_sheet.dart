import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAlertaDetalheHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar este alerta',
    subtitle: 'O que esfriou. A ação é sua — a sugestão não aplica sozinha.',
    tips: const [
      FxHelpTip(
        'Situação',
        'Último treino, check-ins do mês e a mensalidade. Toque no aluno da lista para voltar.',
        icon: 'alert-triangle',
      ),
      FxHelpTip(
        'Sugestão',
        'Texto de reengajamento. Não muda treino nem cobra. Confira antes de mandar.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Ações',
        'Mensagem abre o chat. Relatório é o histórico. Resolver tira da caixa por 24h.',
        icon: 'message-circle',
      ),
    ],
  );
}
