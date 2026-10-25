import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showTreinosListHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Modelos de treino',
    subtitle: 'Semanas inteiras e sessões prontas para aplicar em qualquer aluno.',
    tips: const [
      FxHelpTip(
        'Semanas e Sessões',
        'Semanas são modelos de ficha completos ("Hipertrofia 4 dias"). Sessões são os treinos soltos da sua biblioteca.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Novo modelo',
        'Crie por dias da semana ou salve a ficha de um aluno como modelo. As sessões nascem vazias para você preencher.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Aplicar',
        'Dentro do modelo, "Aplicar em aluno" troca a ficha dele por uma cópia. Editar o modelo depois não muda quem já recebeu.',
        icon: 'users',
      ),
      FxHelpTip(
        'Abrir e ações',
        'Toque no card para abrir. Nas sessões, o menu do card atribui, copia ou remove.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Seleção',
        'Segure um card ou use o checklist. A busca some e as ações sobem para a barra de baixo.',
        icon: 'circle-check',
      ),
    ],
  );
}
