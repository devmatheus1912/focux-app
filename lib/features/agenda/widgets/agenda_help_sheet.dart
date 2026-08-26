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
        'O card em destaque é o próximo atendimento de hoje. Toque para abrir, confirmar ou concluir.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Lacuna',
        'Faixas “min livres” são buracos na agenda. Encaixar preenche o espaço.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Atendimento',
        'Toque no aluno para abrir a ficha, remarcar, WhatsApp, confirmar ou concluir.',
        icon: 'users',
      ),
      FxHelpTip(
        'Calendário',
        'O ícone no topo copia o link iCal para o Google Calendar ou o Apple Calendar.',
        icon: 'article',
      ),
    ],
  );
}
