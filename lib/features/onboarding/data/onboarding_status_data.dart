class OnboardingStatusData {
  final bool perfilCompleto;
  final bool primeiroAlunoAdicionado;
  final bool primeiroTreinoCriado;
  final bool primeiroPagamentoRecebido;
  final int progressoPercentual;

  OnboardingStatusData({
    required this.perfilCompleto,
    required this.primeiroAlunoAdicionado,
    required this.primeiroTreinoCriado,
    required this.primeiroPagamentoRecebido,
    required this.progressoPercentual,
  });

  factory OnboardingStatusData.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusData(
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
      primeiroAlunoAdicionado: json['primeiroAlunoAdicionado'] as bool? ?? false,
      primeiroTreinoCriado: json['primeiroTreinoCriado'] as bool? ?? false,
      primeiroPagamentoRecebido: json['primeiroPagamentoRecebido'] as bool? ?? false,
      progressoPercentual: json['progressoPercentual'] as int? ?? 0,
    );
  }
}
