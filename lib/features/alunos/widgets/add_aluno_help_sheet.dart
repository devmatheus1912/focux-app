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
        icon: 'user',
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
        'Senha provisória',
        'Depois do cadastro, copie o convite ou envie no WhatsApp. O aluno troca a senha no primeiro acesso.',
        icon: 'key',
      ),
    ],
  );
}
