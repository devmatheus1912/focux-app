import 'package:flutter/material.dart';

import '../../../core/theme/hero_teal.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'treino_home_sheet.dart';

Future<void> showTreinoDetailHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: fxTransparent,
    barrierColor: heroScrim(0.34),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return TreinoHelpSheetFrame(
        isDark: isDark,
        icon: Icons.help_outline_rounded,
        title: 'Como montar este treino',
        subtitle:
            'Adicione, ajuste a prescrição e atribua quando o plano estiver pronto.',
        tips: const [
          (
            'Adicionar',
            'O botão principal inclui da biblioteca. O menu do topo também chega lá.',
          ),
          (
            'Prescrição',
            'Toque no exercício para séries, reps, carga e o vídeo de execução.',
          ),
          (
            'Vídeo',
            'O aluno vê a mesma gravação. Specs e envio ficam em Editar prescrição.',
          ),
          (
            'Reordenar',
            'Segure o card e arraste. A ordem é salva neste treino.',
          ),
          (
            'Ações',
            'O menu do exercício duplica, substitui ou remove. O do treino atribui ou exclui.',
          ),
        ],
      );
    },
  );
}
