import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

/// Ajuda contextual do cadastro rápido (pilar 80).
Future<void> showAddAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como cadastrar',
    subtitle: 'Nome e e-mail bastam. O resto é filtro e convite.',
    tips: const [
      FxHelpTip(
        'Obrigatório',
        'Só nome completo e e-mail válidos liberam o Cadastrar. Cada campo diz se é obrigatório ou opcional.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'WhatsApp',
        'Opcional. Se preencher, o convite abre pronto no WhatsApp.',
        icon: FxIcons.telefone,
      ),
      FxHelpTip(
        'Sobre o aluno',
        'Objetivo, gênero e consultoria são opcionais e ajudam nos filtros. Você ajusta depois.',
        icon: FxIcons.meta,
      ),
      FxHelpTip(
        'Link de acesso',
        'Depois do cadastro, envie o link no WhatsApp ou copie. O aluno cria a própria senha. Vale 7 dias.',
        icon: FxIcons.chave,
      ),
    ],
  );
}
