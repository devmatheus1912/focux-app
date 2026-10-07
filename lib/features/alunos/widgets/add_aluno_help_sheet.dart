import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

/// Ajuda contextual do cadastro rápido (pilar 80).
Future<void> showAddAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como cadastrar',
    subtitle: 'Nome e e-mail bastam. O resto é filtro e convite.',
    tips: const [
      FxHelpTip(
        'Obrigatório',
        'Só nome completo e e-mail válidos liberam o Cadastrar.',
        icon: 'users',
      ),
      FxHelpTip(
        'WhatsApp',
        'Opcional. Se preencher, o convite abre pronto no WhatsApp.',
        icon: 'phone',
      ),
      FxHelpTip(
        'Perfil inicial',
        'Objetivo, gênero e consultoria ajudam filtros — você pode ajustar depois.',
        icon: 'flag',
      ),
      FxHelpTip(
        'Link de acesso',
        'Depois do cadastro, envie o link no WhatsApp ou copie. O aluno cria a própria senha. Vale 7 dias.',
        icon: 'key',
      ),
    ],
  );
}
