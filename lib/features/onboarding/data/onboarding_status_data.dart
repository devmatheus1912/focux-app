class OnboardingStatusData {
  final bool perfilCompleto;
  final bool primeiroAlunoAdicionado;
  final bool primeiroTreinoCriado;
  final bool pagamentoConfigurado;
  final bool primeiroPagamentoRecebido;
  final bool pacoteCriado;
  final bool habitoConfigurado;
  final int progressoPercentual;

  OnboardingStatusData({
    required this.perfilCompleto,
    required this.primeiroAlunoAdicionado,
    required this.primeiroTreinoCriado,
    required this.pagamentoConfigurado,
    required this.primeiroPagamentoRecebido,
    required this.pacoteCriado,
    required this.habitoConfigurado,
    required this.progressoPercentual,
  });

  /// Etapas visíveis no card "Sua ativação" — espelha o backend.
  List<bool> get etapasConcluidas => [
        perfilCompleto,
        primeiroAlunoAdicionado,
        primeiroTreinoCriado,
        pacoteCriado,
        habitoConfigurado,
        pagamentoConfigurado,
      ];

  int get etapasTotal => etapasConcluidas.length;

  int get etapasFeitas => etapasConcluidas.where((done) => done).length;

  /// Progresso derivado das etapas exibidas (evita 66% com 4/4 riscados).
  int get progressoExibido {
    if (etapasTotal == 0) return 0;
    return (etapasFeitas * 100 / etapasTotal).round();
  }

  bool get ativacaoCompleta => etapasFeitas >= etapasTotal;

  factory OnboardingStatusData.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusData(
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
      primeiroAlunoAdicionado:
          json['primeiroAlunoAdicionado'] as bool? ?? false,
      primeiroTreinoCriado: json['primeiroTreinoCriado'] as bool? ?? false,
      pagamentoConfigurado:
          json['pagamentoConfigurado'] as bool? ??
          json['primeiroPagamentoRecebido'] as bool? ??
          false,
      primeiroPagamentoRecebido:
          json['primeiroPagamentoRecebido'] as bool? ?? false,
      pacoteCriado: json['pacoteCriado'] as bool? ?? false,
      habitoConfigurado: json['habitoConfigurado'] as bool? ?? false,
      progressoPercentual: json['progressoPercentual'] as int? ?? 0,
    );
  }
}
