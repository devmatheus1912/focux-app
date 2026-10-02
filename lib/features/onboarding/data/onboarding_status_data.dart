class OnboardingStatusData {
  final bool perfilCompleto;
  final bool primeiroAlunoAdicionado;
  final bool primeiroTreinoCriado;
  final bool pagamentoConfigurado;
  final bool pacoteCriado;
  final bool habitoConfigurado;
  final bool linkBioConfigurado;
  final bool wizardCompleto;

  OnboardingStatusData({
    required this.perfilCompleto,
    required this.primeiroAlunoAdicionado,
    required this.primeiroTreinoCriado,
    required this.pagamentoConfigurado,
    required this.pacoteCriado,
    required this.habitoConfigurado,
    required this.linkBioConfigurado,
    this.wizardCompleto = false,
  });

  /// Ordem canônica: aluno → treino → perfil → PIX → pacote → hábito → link.
  /// [hiddenSteps]: ids de passo fora do plano atual (não contam).
  List<bool> etapasConcluidas({
    bool includeLinkBio = true,
    Set<String> hiddenSteps = const {},
  }) => [
    for (final (id, done) in [
      ('primeiro-aluno', primeiroAlunoAdicionado),
      ('primeiro-treino', primeiroTreinoCriado),
      ('perfil', perfilCompleto),
      ('pagamento', pagamentoConfigurado),
      ('pacote', pacoteCriado),
      ('habito', habitoConfigurado),
      if (includeLinkBio) ('link-bio', linkBioConfigurado),
    ])
      if (!hiddenSteps.contains(id)) done,
  ];

  int etapasTotal({
    bool includeLinkBio = true,
    Set<String> hiddenSteps = const {},
  }) =>
      etapasConcluidas(
        includeLinkBio: includeLinkBio,
        hiddenSteps: hiddenSteps,
      ).length;

  int etapasFeitas({
    bool includeLinkBio = true,
    Set<String> hiddenSteps = const {},
  }) =>
      etapasConcluidas(
        includeLinkBio: includeLinkBio,
        hiddenSteps: hiddenSteps,
      ).where((done) => done).length;

  /// Progresso derivado das etapas exibidas (evita % divergente da UI).
  int progressoExibido({
    bool includeLinkBio = true,
    Set<String> hiddenSteps = const {},
  }) {
    final total = etapasTotal(
      includeLinkBio: includeLinkBio,
      hiddenSteps: hiddenSteps,
    );
    if (total == 0) return 0;
    return (etapasFeitas(
              includeLinkBio: includeLinkBio,
              hiddenSteps: hiddenSteps,
            ) *
            100 /
            total)
        .round();
  }

  /// Fez todas as etapas **ou** encerrou o wizard (pular gated / concluir).
  bool ativacaoCompleta({
    bool includeLinkBio = true,
    Set<String> hiddenSteps = const {},
  }) =>
      wizardCompleto ||
      etapasFeitas(includeLinkBio: includeLinkBio, hiddenSteps: hiddenSteps) >=
          etapasTotal(includeLinkBio: includeLinkBio, hiddenSteps: hiddenSteps);

  factory OnboardingStatusData.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusData(
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
      primeiroAlunoAdicionado:
          json['primeiroAlunoAdicionado'] as bool? ?? false,
      primeiroTreinoCriado: json['primeiroTreinoCriado'] as bool? ?? false,
      // `primeiroPagamentoRecebido` era o campo antigo; só fallback de parse.
      pagamentoConfigurado:
          json['pagamentoConfigurado'] as bool? ??
          json['primeiroPagamentoRecebido'] as bool? ??
          false,
      pacoteCriado: json['pacoteCriado'] as bool? ?? false,
      habitoConfigurado: json['habitoConfigurado'] as bool? ?? false,
      linkBioConfigurado: json['linkBioConfigurado'] as bool? ?? false,
      wizardCompleto: json['wizardCompleto'] as bool? ?? false,
    );
  }
}
