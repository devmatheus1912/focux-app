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
  List<bool> etapasConcluidas({bool includeLinkBio = true}) => [
    primeiroAlunoAdicionado,
    primeiroTreinoCriado,
    perfilCompleto,
    pagamentoConfigurado,
    pacoteCriado,
    habitoConfigurado,
    if (includeLinkBio) linkBioConfigurado,
  ];

  int etapasTotal({bool includeLinkBio = true}) =>
      etapasConcluidas(includeLinkBio: includeLinkBio).length;

  int etapasFeitas({bool includeLinkBio = true}) =>
      etapasConcluidas(
        includeLinkBio: includeLinkBio,
      ).where((done) => done).length;

  /// Progresso derivado das etapas exibidas (evita % divergente da UI).
  int progressoExibido({bool includeLinkBio = true}) {
    final total = etapasTotal(includeLinkBio: includeLinkBio);
    if (total == 0) return 0;
    return (etapasFeitas(includeLinkBio: includeLinkBio) * 100 / total).round();
  }

  /// Fez todas as etapas **ou** encerrou o wizard (pular gated / concluir).
  bool ativacaoCompleta({bool includeLinkBio = true}) =>
      wizardCompleto ||
      etapasFeitas(includeLinkBio: includeLinkBio) >=
          etapasTotal(includeLinkBio: includeLinkBio);

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
