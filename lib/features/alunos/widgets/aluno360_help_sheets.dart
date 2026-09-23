import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAluno360EvolucaoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Aba Evolução',
    subtitle: 'Sinais de progresso, timeline e peso — sem repetir alertas.',
    tips: const [
      FxHelpTip(
        'Evolução inteligente',
        'Gráfico de volume após check-ins. Peça check-in se ainda estiver vazio.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Linha do tempo',
        'Radar, check-ins, chat e medidas recentes. Toque para ver detalhe ou ir ao destino.',
        icon: 'article',
      ),
      FxHelpTip(
        'Peso · tendência',
        'Última balança e sparkline. Radar P0 some aqui se a timeline já mostrar o mapa pendente.',
        icon: 'dumbbell',
      ),
    ],
  );
}

Future<void> showAluno360OperacaoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Aba Operação',
    subtitle: 'O que fazer com este aluno hoje — em ordem de prioridade.',
    tips: const [
      FxHelpTip(
        'Próximo contato',
        'Linha de status. Toque em Agendar para marcar feito, data ou adiar — sem competir com o botão da base.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Status operacional',
        'Aderência e dias sem treino. A faixa de 7 dias é o detalhe da semana, não um segundo calendário.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Prioridade do dia',
        'Uma linha de contexto. Atualizar regenera a sugestão e troca o botão de baixo — sem segundo card.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Botão da base',
        'Ação principal do dia (contato, tarefa, sono ou treino). Um só por aba.',
        icon: 'target',
      ),
    ],
  );
}

Future<void> showAluno360CopilotHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Prioridade do dia',
    subtitle: 'Leitura rápida antes de agir — sem substituir seu julgamento.',
    tips: const [
      FxHelpTip(
        'Perfil',
        'Quanto do cadastro está pronto para prescrever treino com segurança.',
        icon: 'user',
      ),
      FxHelpTip(
        'Financeiro',
        'Bloqueio operacional por mensalidade. Vermelho = resolver cobrança antes.',
        icon: 'dollar-sign',
      ),
      FxHelpTip(
        'Autonomia',
        'Engajamento com tarefas e conteúdos enviados pelo app.',
        icon: 'users',
      ),
      FxHelpTip(
        'Contexto',
        'Equipamentos, wearable e gaps que influenciam a sugestão.',
        icon: 'zap',
      ),
      FxHelpTip(
        'Atualizar IA',
        'Regenera a sugestão. Plano PRO necessário — upgrade aparece automaticamente se faltar.',
        icon: 'spark',
      ),
    ],
  );
}

Future<void> showAluno360EvolucaoInteligenteHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Evolução inteligente',
    subtitle: 'Sinais de volume e tendência — só após check-ins registrados.',
    tips: const [
      FxHelpTip(
        'Sem dados ainda',
        'Peça um check-in ou registre treino concluído. A linha do tempo abaixo já conta como interação.',
        icon: 'alert-triangle',
      ),
      FxHelpTip(
        'Volume',
        'Soma semanal/mensal de treino concluído. O gráfico aparece com pelo menos uma semana.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Próxima ação',
        'Sugestão operacional derivada do histórico — ajuste o treino se fizer sentido.',
        icon: 'target',
      ),
    ],
  );
}

Future<void> showAluno360TimelineHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Linha do tempo 360',
    subtitle: 'Últimos eventos consolidados — radar, check-in, chat e medidas.',
    tips: const [
      FxHelpTip(
        'Radar Focux',
        'Pontuação de completude corporal. P0 = mapa corporal pendente — registre na evolução.',
        icon: 'target',
      ),
      FxHelpTip(
        'Prioridade P0/P1',
        'P0 exige ação hoje; P1 é importante mas não bloqueia.',
        icon: 'target',
      ),
      FxHelpTip(
        'Ver todos',
        'Abre o histórico completo paginado quando houver mais de três sinais.',
        icon: 'article',
      ),
    ],
  );
}

Future<void> showAluno360PesoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Peso · tendência',
    subtitle: 'Última balança e sparkline das medições recentes.',
    tips: const [
      FxHelpTip(
        'Primeira medida',
        'Registre peso na evolução corporal para liberar a tendência.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Radar P0',
        'Se o radar pedir mapa corporal, peso e medidas entram na mesma tela de evolução.',
        icon: 'target',
      ),
    ],
  );
}

Future<void> showAluno360FerramentasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Aba Ferramentas',
    subtitle: 'P0 no fold; o catálogo completo fica em Mais ferramentas.',
    tips: const [
      FxHelpTip(
        'Medidas',
        'Resumo do que falta no perfil e na composição corporal. Um toque abre o destino certo.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Atalhos do aluno',
        'Só o que precisa de atenção agora. Duplicados do sticky ficam em Mais.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Mais ferramentas',
        'Catálogo completo em uma linha — não é o botão da base.',
        icon: 'people',
      ),
    ],
  );
}

Future<void> showAluno360StatusOperacionalHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Status operacional',
    subtitle: 'Diagnóstico rápido antes de prescrever ou cobrar.',
    tips: const [
      FxHelpTip(
        'Prontidão',
        'Índice composto de engajamento e dados do aluno.',
        icon: 'zap',
      ),
      FxHelpTip(
        'Aderência · 30 dias',
        'Percentual de treinos concluídos entre os iniciados nos últimos 30 dias — não é o mesmo que check-ins da semana.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Faixa da semana',
        'Detalhe da aderência: verde = check-in; laranja = sem registro; anel = hoje. Pedir check-in some quando o botão da base já é o P0.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Sem treino',
        'Dias parados desde o último registro — alerta quando passa do limite da sua config.',
        icon: 'alert-triangle',
      ),
    ],
  );
}
