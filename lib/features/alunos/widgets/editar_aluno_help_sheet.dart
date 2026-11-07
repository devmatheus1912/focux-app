import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showEditarAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Editar aluno',
    subtitle: 'Atualiza o perfil que o 360 e a prescrição usam.',
    tips: const [
      FxHelpTip(
        'Obrigatório',
        'O nome é obrigatório e o e-mail só aparece para leitura. O restante é opcional.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Contato',
        'Telefone e WhatsApp entram no follow-up. WhatsApp usa máscara BR.',
        icon: FxIcons.telefone,
      ),
      FxHelpTip(
        'Consultoria',
        'Online, presencial ou híbrido — o mesmo filtro do broadcast.',
        icon: FxIcons.meta,
      ),
    ],
  );
}
