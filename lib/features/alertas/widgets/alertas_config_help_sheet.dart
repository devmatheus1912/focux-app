import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAlertasConfigHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Quando dispara',
    subtitle: 'Estes limiares valem para a lista de alertas e para o risco no 360.',
    tips: const [
      FxHelpTip(
        'Dias sem treino',
        'Entra na caixa se o último treino passou deste prazo. O último treino é de verdade — não só os 30 dias.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Aderência',
        'Percentual de check-ins concluídos nos últimos 30 dias. Abaixo do mínimo, alerta.',
        icon: 'target',
      ),
      FxHelpTip(
        'Salvar',
        'Vale na hora. Resolver um aluno na lista continua sendo snooze de 24h, não muda o limiar.',
        icon: 'circle-check',
      ),
    ],
  );
}
