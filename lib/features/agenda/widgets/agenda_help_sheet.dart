import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAgendaHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a agenda',
    subtitle: 'Marque o dia, encaixe o aluno e confirme o horário.',
    tips: const [
      FxHelpTip(
        'Dia',
        'Toque no dia para ver os horários. As setas mudam a semana — os dados vêm do servidor.',
      ),
      FxHelpTip(
        'Atendimento',
        'Toque no aluno para abrir a ficha, confirmar, concluir ou avisar no WhatsApp. O título opcional vira nota.',
      ),
      FxHelpTip(
        'Hoje',
        'Fora do dia atual, o ícone de hoje (calendário com o dia) volta para agora.',
      ),
      FxHelpTip(
        'iCal',
        'O ícone de calendário copia o link para o Google Calendar ou o Apple Calendar.',
      ),
    ],
  );
}
