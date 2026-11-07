import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showAlertasConfigHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Quando dispara',
    subtitle:
        'Estes limiares valem para a lista de alertas e para o risco no 360.',
    tips: const [
      FxHelpTip(
        'Dias sem treino',
        'Entra na caixa se o último treino passou deste prazo. O último treino é de verdade — não só os 30 dias.',
        icon: FxIcons.calendario,
      ),
      FxHelpTip(
        'Aderência',
        'Percentual de check-ins concluídos nos últimos 30 dias. Abaixo do mínimo, alerta.',
        icon: FxIcons.alvo,
      ),
      FxHelpTip(
        'Salvar',
        'Vale na hora. Adiar 24h na lista continua sendo snooze, não muda o limiar.',
        icon: FxIcons.concluido,
      ),
    ],
  );
}
