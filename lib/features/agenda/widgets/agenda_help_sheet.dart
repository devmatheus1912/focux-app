import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAgendaHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a agenda',
    subtitle: 'O dia do personal: próximo horário, lacunas e a ficha do aluno.',
    tips: const [
      FxHelpTip(
        'Próximo',
        'O card verde é o próximo atendimento de hoje. Toque para abrir, confirmar ou concluir.',
      ),
      FxHelpTip(
        'Lacuna',
        'Faixas “min livres” são buracos na agenda. Toque em Encaixar para preencher.',
      ),
      FxHelpTip(
        'Atendimento',
        'Toque no aluno para abrir a ficha, remarcar, WhatsApp, confirmar ou concluir.',
      ),
      FxHelpTip(
        'iCal',
        'O ícone de calendário no topo copia o link para o Google Calendar ou o Apple Calendar.',
      ),
    ],
  );
}
