enum IaAlunoHubView { chat, progressao }

String iaAlunoHubViewLabel(IaAlunoHubView view) => switch (view) {
  IaAlunoHubView.chat => 'Chat',
  IaAlunoHubView.progressao => 'Progressão',
};

String iaAlunoHubSubtitle(IaAlunoHubView view) => switch (view) {
  IaAlunoHubView.chat => 'Pergunte sobre treino, dieta ou saúde',
  IaAlunoHubView.progressao => 'Recomendações de carga, só se você pedir',
};

const iaAlunoComoCalculamos =
    'Chat e progressão só rodam se você pedir. Nada é aplicado sozinho.';

const iaChatComoCalculamos =
    'O assistente responde ao que você escreve. Não aplica treino nem dieta.';
