import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

/// Visão geral do cadastro na biblioteca (ícone `?` do app bar).
Future<void> showNovoExercicioHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como cadastrar',
    subtitle: 'Nome e grupo principal bastam. O resto refina busca e prescrição.',
    tips: const [
      FxHelpTip(
        'Identidade',
        'Nome, grupo muscular, modalidade e padrão de movimento organizam a biblioteca.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Perfil rápido',
        'Atalhos para academia, casa ou mobilidade — preenchem equipamentos e espaços.',
        icon: 'zap',
      ),
      FxHelpTip(
        'Ambiente',
        'Equipamentos e espaços filtram onde o exercício aparece na busca.',
        icon: 'search',
      ),
      FxHelpTip(
        'Orientação',
        'Descrição, erros comuns e contraindicações são opcionais e aparecem para o aluno.',
        icon: 'article',
      ),
    ],
  );
}

Future<void> showNovoExercicioIdentidadeHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Identidade',
    subtitle: 'Como o exercício aparece na biblioteca e nos filtros.',
    tips: const [
      FxHelpTip(
        'Nome',
        'Use o nome que você fala com o aluno — curto e reconhecível.',
        icon: 'article',
      ),
      FxHelpTip(
        'Grupo principal',
        'Obrigatório. Define o músculo-alvo principal na busca e nas sugestões.',
        icon: 'target',
      ),
      FxHelpTip(
        'Modalidade e dificuldade',
        'Ajudam a separar musculação, mobilidade, cardio e o nível sugerido.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Padrão de movimento',
        'Empurrar, puxar, agachar… melhora recomendações e modelos de treino.',
        icon: 'route',
      ),
    ],
  );
}

Future<void> showNovoExercicioPerfilRapidoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Perfil rápido',
    subtitle: 'Atalhos para começar sem configurar tudo campo a campo.',
    tips: const [
      FxHelpTip(
        'Academia',
        'Halter, barra, máquina, polia e banco — ambientes de academia completa ou básica.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Casa',
        'Halter, kettlebell, banda e peso corporal — casa equipada.',
        icon: 'home',
      ),
      FxHelpTip(
        'Peso corporal',
        'Sem aparelhos — casa sem equipamento ou ao ar livre.',
        icon: 'target',
      ),
      FxHelpTip(
        'Mobilidade',
        'Modalidade mobilidade com padrão dinâmico e equipamentos leves.',
        icon: 'spark',
      ),
    ],
    footer: 'Você pode ajustar qualquer campo depois de escolher um atalho.',
  );
}

Future<void> showNovoExercicioExecucaoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Execução',
    subtitle: 'Como o movimento entra na série prescrita.',
    tips: const [
      FxHelpTip(
        'Unilateral',
        'Ative quando cada lado deve ser feito separadamente (ex.: 12 por braço).',
        icon: 'route',
      ),
      FxHelpTip(
        'Bilateral',
        'Desligado = uma série conta o movimento nos dois lados juntos.',
        icon: 'circle-check',
      ),
    ],
  );
}

Future<void> showNovoExercicioAmbienteHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Ambiente',
    subtitle: 'Onde e com o quê o aluno pode executar este exercício.',
    tips: const [
      FxHelpTip(
        'Equipamentos',
        'Marque tudo que serve — o exercício aparece quando o filtro bate.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Espaços',
        'Academia, casa ou outdoor — alinha com o perfil do aluno na busca.',
        icon: 'home',
      ),
      FxHelpTip(
        'Vários de cada',
        'Pode selecionar mais de um. Nada marcado limita demais a descoberta.',
        icon: 'search',
      ),
    ],
  );
}

Future<void> showNovoExercicioOrientacaoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Orientação opcional',
    subtitle: 'Textos que o aluno vê ao abrir o exercício.',
    tips: const [
      FxHelpTip(
        'Descrição curta',
        'Uma frase objetiva de como executar — sem textão.',
        icon: 'article',
      ),
      FxHelpTip(
        'Erros comuns',
        'O que evitar na postura ou no movimento.',
        icon: 'alert-triangle',
      ),
      FxHelpTip(
        'Contraindicações',
        'Quando adaptar ou não prescrever — lesão, mobilidade, etc.',
        icon: 'bell',
      ),
    ],
    footer: 'Tudo opcional. Pode preencher depois de salvar.',
  );
}
