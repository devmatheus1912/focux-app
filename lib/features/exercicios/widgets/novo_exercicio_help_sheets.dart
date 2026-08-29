import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

/// Único help do cadastro — ícone `?` do app bar (padrão Perfil / Novo aluno).
Future<void> showNovoExercicioHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como cadastrar',
    subtitle:
        'Nome e grupo principal bastam. O resto refina busca e a ficha do aluno.',
    tips: const [
      FxHelpTip(
        'Identidade',
        'Nome, grupo, modalidade, padrão e unilateral organizam a biblioteca e a prescrição.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Perfil rápido',
        'Atalhos academia, casa, peso corporal ou mobilidade — preenchem equipamentos e espaços.',
        icon: 'zap',
      ),
      FxHelpTip(
        'Ambiente',
        'Equipamentos e espaços definem onde o exercício aparece nos filtros da busca.',
        icon: 'search',
      ),
      FxHelpTip(
        'Orientação',
        'Descrição, erros comuns e contraindicações são opcionais e aparecem para o aluno.',
        icon: 'article',
      ),
    ],
    footer: 'Dica: escolha o grupo principal antes de salvar — é o único campo obrigatório além do nome.',
  );
}
