/// Status de exibição vindo do servidor. Risco e antifraude nunca chegam ao app.
enum ReferralIndicacaoStatus {
  pending,
  trial,
  rewardGranted,
  underReview,
  noReward,
  reversed,
  notEligible;

  static ReferralIndicacaoStatus fromApi(String? raw) {
    switch (raw) {
      case 'PENDING':
        return pending;
      case 'TRIAL':
        return trial;
      case 'REWARD_GRANTED':
        return rewardGranted;
      case 'UNDER_REVIEW':
        return underReview;
      case 'NO_REWARD':
        return noReward;
      case 'REVERSED':
        return reversed;
      default:
        return notEligible;
    }
  }
}

class ReferralIndicacao {
  const ReferralIndicacao({
    required this.id,
    required this.nomeMascarado,
    required this.status,
    required this.dias,
    this.criadoEm,
    this.convertidoEm,
  });

  final int id;
  final String nomeMascarado;
  final ReferralIndicacaoStatus status;
  final int dias;
  final DateTime? criadoEm;
  final DateTime? convertidoEm;

  factory ReferralIndicacao.fromJson(Map<String, dynamic> j) =>
      ReferralIndicacao(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nomeMascarado: j['nomeMascarado'] as String? ?? '',
        status: ReferralIndicacaoStatus.fromApi(j['status'] as String?),
        dias: (j['dias'] as num?)?.toInt() ?? 0,
        criadoEm: DateTime.tryParse(j['criadoEm'] as String? ?? ''),
        convertidoEm: DateTime.tryParse(j['convertidoEm'] as String? ?? ''),
      );
}

/// Painel de indicação. Todos os números da campanha vêm do servidor; o app não conhece regra.
class ReferralInfo {
  const ReferralInfo({
    required this.codigo,
    required this.usosTotais,
    required this.linkCompartilhamento,
    this.campanhaAtiva = false,
    this.recompensasConcedidas = 0,
    this.recompensasEmAnalise = 0,
    this.maxRecompensas,
    this.diasGanhos = 0,
    this.tetoDias,
    this.diasPorIndicacao,
    this.descontoIndicadoPct,
    this.limiteAtingido = false,
    this.indicacoes = const [],
  });

  final String codigo;
  final int usosTotais;
  final String linkCompartilhamento;
  final bool campanhaAtiva;
  final int recompensasConcedidas;
  final int recompensasEmAnalise;
  final int? maxRecompensas;
  final int diasGanhos;
  final int? tetoDias;
  final int? diasPorIndicacao;
  final int? descontoIndicadoPct;
  final bool limiteAtingido;
  final List<ReferralIndicacao> indicacoes;

  factory ReferralInfo.fromJson(Map<String, dynamic> j) => ReferralInfo(
    codigo: j['codigo'] as String? ?? '',
    usosTotais: (j['usosTotais'] as num?)?.toInt() ?? 0,
    linkCompartilhamento: j['linkCompartilhamento'] as String? ?? '',
    campanhaAtiva: j['campanhaAtiva'] as bool? ?? false,
    recompensasConcedidas: (j['recompensasConcedidas'] as num?)?.toInt() ?? 0,
    recompensasEmAnalise: (j['recompensasEmAnalise'] as num?)?.toInt() ?? 0,
    maxRecompensas: (j['maxRecompensas'] as num?)?.toInt(),
    diasGanhos: (j['diasGanhos'] as num?)?.toInt() ?? 0,
    tetoDias: (j['tetoDias'] as num?)?.toInt(),
    diasPorIndicacao: (j['diasPorIndicacao'] as num?)?.toInt(),
    descontoIndicadoPct: (j['descontoIndicadoPct'] as num?)?.toInt(),
    limiteAtingido: j['limiteAtingido'] as bool? ?? false,
    indicacoes: (j['indicacoes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ReferralIndicacao.fromJson)
        .toList(growable: false),
  );
}
