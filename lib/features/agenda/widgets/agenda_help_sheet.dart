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
        'Toque no dia da semana para ver os atendimentos. O mês muda nas setas.',
      ),
      FxHelpTip(
        'Novo',
        'Escolha o aluno, o início e o fim. Ao confirmar o início, o fim vem com +1 hora.',
      ),
      FxHelpTip(
        'Título',
        'Opcional. Avaliação, retorno ou o foco da sessão — o nome do aluno já identifica o card.',
      ),
      FxHelpTip(
        'iCal',
        'O ícone de calendário copia o link para o Google Calendar ou o Apple Calendar.',
      ),
    ],
  );
}
