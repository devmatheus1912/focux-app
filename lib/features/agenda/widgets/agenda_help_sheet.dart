import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../utils/agenda_display.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showAgendaHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a agenda',
    subtitle: 'O dia do personal: próximo horário, lacunas e a ficha do aluno.',
    tips: const [
      FxHelpTip('Como calculamos', agendaComoCalculamos),
      FxHelpTip(
        'Próximo',
        'O card em destaque é o próximo atendimento de hoje. Toque para abrir, confirmar ou concluir.',
        icon: FxIcons.ia,
      ),
      FxHelpTip(
        'Mês',
        'Pontos marcam dias com atendimento. Arraste o calendário para trocar o mês; Hoje volta para o dia atual.',
        icon: FxIcons.calendario,
      ),
      FxHelpTip(
        'Lacuna',
        'Faixas “min livres” são buracos na agenda. Encaixar preenche o espaço.',
        icon: FxIcons.calendario,
      ),
      FxHelpTip(
        'Atendimento',
        'Toque no aluno para abrir a ficha, remarcar, WhatsApp, confirmar ou concluir.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Calendário',
        'O ícone no topo copia o link iCal para o Google Calendar ou o Apple Calendar.',
        icon: FxIcons.artigo,
      ),
    ],
  );
}
