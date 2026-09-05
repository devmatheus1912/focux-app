/// Modelo de plano SaaS — arquivo isolado para evitar ciclo com paywall_vitrine.
///
/// Só campos que a UI de Assinatura/checkout ainda lê. Features de plano vêm de
/// `PlanoFeatures` / entitlements — não deste DTO de preço.
class Plano {
  final int id;
  final String nome;
  final double precoMensal;
  final double? precoAnual;
  final double? precoAnualMensalEquiv;
  final double? equivMensalNoAnual;
  final String? labelDescontoAnual;
  final String? labelEconomiaAnual;

  const Plano({
    required this.id,
    required this.nome,
    required this.precoMensal,
    this.precoAnual,
    this.precoAnualMensalEquiv,
    this.equivMensalNoAnual,
    this.labelDescontoAnual,
    this.labelEconomiaAnual,
  });

  factory Plano.fromJson(Map<String, dynamic> json) => Plano(
    id: json['id'] as int,
    nome: json['nome'] as String,
    precoMensal: (json['precoMensal'] as num).toDouble(),
    precoAnual: (json['precoAnual'] as num?)?.toDouble(),
    precoAnualMensalEquiv: (json['precoAnualMensalEquiv'] as num?)?.toDouble(),
    equivMensalNoAnual: (json['equivMensalNoAnual'] as num?)?.toDouble(),
    labelDescontoAnual: json['labelDescontoAnual'] as String?,
    labelEconomiaAnual: json['labelEconomiaAnual'] as String?,
  );
}
