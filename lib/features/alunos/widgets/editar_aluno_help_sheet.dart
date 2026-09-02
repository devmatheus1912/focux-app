import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showEditarAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Editar aluno',
    subtitle: 'Atualiza o perfil que o 360 e a prescrição usam.',
    tips: const [
      FxHelpTip(
        'Obrigatório',
        'Nome completo e e-mail válidos. O restante pode ficar em branco.',
        icon: 'users',
      ),
      FxHelpTip(
        'Contato',
        'Telefone e WhatsApp entram no follow-up. WhatsApp usa máscara BR.',
        icon: 'phone',
      ),
      FxHelpTip(
        'Consultoria',
        'Online, presencial ou híbrido — o mesmo filtro do broadcast.',
        icon: 'flag',
      ),
    ],
  );
}
