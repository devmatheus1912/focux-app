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
        'Texto local na hora. Melhorar com IA é opt-in e não muda treino nem cobra.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Ações',
        'Enviar mensagem confirma o texto e manda no chat. Abrir o chat é o fio. Adiar 24h tira da caixa por um dia.',
        icon: 'message-circle',
      ),
    ],
  );
}
