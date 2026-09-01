enum IaAlunoHubView { chat, progressao }

String iaAlunoHubViewLabel(IaAlunoHubView view) => switch (view) {
  IaAlunoHubView.chat => 'Chat',
  IaAlunoHubView.progressao => 'Progressão',
};

String iaAlunoHubSubtitle(IaAlunoHubView view) => switch (view) {
  IaAlunoHubView.chat => 'Pergunte sobre treino, dieta ou saúde',
  IaAlunoHubView.progressao => 'Recomendações de carga, só se você pedir',
};
