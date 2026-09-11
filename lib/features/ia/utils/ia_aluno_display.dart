enum IaAlunoHubView { chat }

String iaAlunoHubViewLabel(IaAlunoHubView view) => switch (view) {
  IaAlunoHubView.chat => 'Chat',
};

String iaAlunoHubSubtitle(IaAlunoHubView view) => switch (view) {
  IaAlunoHubView.chat => 'Pergunte sobre treino ou saúde',
};

const iaAlunoComoCalculamos =
    'O assistente só responde se você pedir. Progressão de carga é do personal — não há Assinar Pro no app do aluno.';

const iaChatComoCalculamos =
    'O assistente responde ao que você escreve. Não aplica treino sozinho.';
