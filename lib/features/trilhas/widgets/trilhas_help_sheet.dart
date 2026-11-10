import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showTrilhasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar as trilhas',
    subtitle: 'Um caminho em etapas até uma conquista.',
    tips: const [
      FxHelpTip(
        'Para que serve',
        'Conquistas que não são número da balança: a primeira barra fixa, correr 5 km, agachar com técnica. Meta de peso ou medida fica em Evolução.',
        icon: FxIcons.rota,
      ),
      FxHelpTip(
        'Nova trilha',
        'Comece de um modelo ou escreva de 2 a 10 etapas. O aluno recebe um aviso.',
        icon: FxIcons.adicionar,
      ),
      FxHelpTip(
        'Etapas',
        'O aluno marca a etapa quando consegue e você recebe um aviso. Toque numa etapa para marcar, desfazer ou remover.',
        icon: FxIcons.concluido,
      ),
    ],
  );
}

Future<void> showAlunoTrilhasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Trilhas',
    subtitle: 'Caminhos em etapas que seu personal montou.',
    tips: const [
      FxHelpTip(
        'Consegui',
        'Quando conseguir a etapa atual, toque em "Consegui". Seu personal recebe um aviso.',
        icon: FxIcons.concluido,
      ),
      FxHelpTip(
        'Errou?',
        'Toque numa etapa feita para desfazer.',
        icon: FxIcons.desfazer,
      ),
    ],
  );
}
