/// Modelo de plano SaaS — arquivo isolado para evitar ciclo com paywall_vitrine.
class Plano {
  final int id;
  final String nome;
  final double precoMensal;
  final double? precoAnual;
  final double? precoAnualMensalEquiv;
  final int? limiteAlunos;
  final bool temWhiteLabel;
  final bool temFinanceiro;
  final bool temAgenda;
  final bool temRelatorios;
  final bool temLandingCompleta;
  final String? displayName;
  final String? subtitle;
  final String? badge;
  final String? roiTag;
  final int? tierOrder;

  const Plano({
    required this.id,
    required this.nome,
    required this.precoMensal,
    this.precoAnual,
    this.precoAnualMensalEquiv,
    this.limiteAlunos,
    required this.temWhiteLabel,
    required this.temFinanceiro,
    required this.temAgenda,
    required this.temRelatorios,
    this.temLandingCompleta = false,
    this.displayName,
    this.subtitle,
    this.badge,
    this.roiTag,
    this.tierOrder,
  });

  double annualPriceOrComputed() =>
      precoAnual ?? (precoMensal * 12 * 0.8);

  factory Plano.fromJson(Map<String, dynamic> json) => Plano(
        id: json['id'] as int,
        nome: json['nome'] as String,
        precoMensal: (json['precoMensal'] as num).toDouble(),
        precoAnual: (json['precoAnual'] as num?)?.toDouble(),
        precoAnualMensalEquiv: (json['precoAnualMensalEquiv'] as num?)?.toDouble(),
        limiteAlunos: json['limiteAlunos'] as int?,
        temWhiteLabel: json['temWhiteLabel'] as bool,
        temFinanceiro: json['temFinanceiro'] as bool,
        temAgenda: json['temAgenda'] as bool,
        temRelatorios: json['temRelatorios'] as bool,
        temLandingCompleta: json['temLandingCompleta'] as bool? ?? false,
        displayName: json['displayName'] as String?,
        subtitle: json['subtitle'] as String?,
        badge: json['badge'] as String?,
        roiTag: json['roiTag'] as String?,
        tierOrder: (json['tierOrder'] as num?)?.toInt(),
      );
}
